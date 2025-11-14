{ config, lib, pkgs, ... }:

let
  # Sync script that connects to PostgreSQL via Tailscale
  notesSync = pkgs.writeShellScriptBin "notes-sync" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.python3.withPackages (ps: [ ps.psycopg2 ])}/bin/python3 ${./scripts/notes-sync.py} "$@"
  '';
in
{
  # Install the sync script
  home.packages = [ notesSync ];

  # Create the Python sync script
  home.file.".local/share/notes-sync/notes-sync.py" = {
    text = ''
      #!/usr/bin/env python3
      """
      Notes Sync Script
      Syncs zk notes (markdown) and org-roam notes (org files) with PostgreSQL database
      Connects via Tailscale network
      """

      import os
      import sys
      import hashlib
      import psycopg2
      import argparse
      from pathlib import Path
      from datetime import datetime
      import socket

      # Configuration - connects to container via Tailscale
      DB_HOST = "notes-db"  # Tailscale hostname
      DB_PORT = 5432
      DB_NAME = "notes_db"
      DB_USER = "notes_user"
      DB_PASSWORD = os.environ.get("NOTES_DB_PASSWORD", "")

      ZK_NOTES_DIR = Path.home() / "Notes"
      ORGROAM_NOTES_DIR = Path.home() / "org" / "roam"
      MACHINE_ID = socket.gethostname()


      def get_db_connection():
          """Connect to PostgreSQL database"""
          try:
              conn = psycopg2.connect(
                  host=DB_HOST,
                  port=DB_PORT,
                  dbname=DB_NAME,
                  user=DB_USER,
                  password=DB_PASSWORD
              )
              return conn
          except Exception as e:
              print(f"Error connecting to database: {e}")
              sys.exit(1)


      def compute_checksum(content):
          """Calculate MD5 checksum of content"""
          return hashlib.md5(content.encode('utf-8')).hexdigest()


      def extract_title_from_markdown(content):
          """Extract title from markdown file (first # heading or filename)"""
          lines = content.split('\n')
          for line in lines:
              if line.startswith('# '):
                  return line[2:].strip()
          return ""


      def extract_title_from_org(content):
          """Extract title from org-mode file (#+TITLE: or first heading)"""
          lines = content.split('\n')
          for line in lines:
              if line.startswith('#+TITLE:'):
                  return line[8:].strip()
              if line.startswith('* '):
                  return line[2:].strip()
          return ""


      def push_notes():
          """Push local notes to database"""
          conn = get_db_connection()
          cursor = conn.cursor()

          pushed_count = 0
          updated_count = 0

          # Push zk notes (markdown)
          print(f"Scanning {ZK_NOTES_DIR} for markdown notes...")
          if ZK_NOTES_DIR.exists():
              for note_file in ZK_NOTES_DIR.rglob("*.md"):
                  if ".zk" in note_file.parts or ".obsidian" in note_file.parts or ".Trash" in note_file.parts:
                      continue

                  try:
                      with open(note_file, 'r', encoding='utf-8') as f:
                          content = f.read()

                      relative_path = str(note_file.relative_to(ZK_NOTES_DIR))
                      checksum = compute_checksum(content)
                      title = extract_title_from_markdown(content)
                      modified_at = datetime.fromtimestamp(note_file.stat().st_mtime)

                      cursor.execute(
                          "SELECT checksum FROM notes WHERE path = %s AND note_type = 'zk'",
                          (relative_path,)
                      )
                      result = cursor.fetchone()

                      if result is None:
                          cursor.execute(
                              """INSERT INTO notes (path, title, content, note_type, checksum, modified_at)
                                 VALUES (%s, %s, %s, 'zk', %s, %s)""",
                              (relative_path, title, content, checksum, modified_at)
                          )
                          pushed_count += 1
                          print(f"  [+] {relative_path}")
                      elif result[0] != checksum:
                          cursor.execute(
                              """UPDATE notes
                                 SET title = %s, content = %s, checksum = %s, modified_at = %s
                                 WHERE path = %s AND note_type = 'zk'""",
                              (title, content, checksum, modified_at, relative_path)
                          )
                          updated_count += 1
                          print(f"  [~] {relative_path}")

                  except Exception as e:
                      print(f"  [!] Error processing {note_file}: {e}")

          # Push org-roam notes
          print(f"\nScanning {ORGROAM_NOTES_DIR} for org-roam notes...")
          if ORGROAM_NOTES_DIR.exists():
              for note_file in ORGROAM_NOTES_DIR.rglob("*.org"):
                  try:
                      with open(note_file, 'r', encoding='utf-8') as f:
                          content = f.read()

                      relative_path = str(note_file.relative_to(ORGROAM_NOTES_DIR))
                      checksum = compute_checksum(content)
                      title = extract_title_from_org(content)
                      modified_at = datetime.fromtimestamp(note_file.stat().st_mtime)

                      cursor.execute(
                          "SELECT checksum FROM notes WHERE path = %s AND note_type = 'org-roam'",
                          (relative_path,)
                      )
                      result = cursor.fetchone()

                      if result is None:
                          cursor.execute(
                              """INSERT INTO notes (path, title, content, note_type, checksum, modified_at)
                                 VALUES (%s, %s, %s, 'org-roam', %s, %s)""",
                              (relative_path, title, content, checksum, modified_at)
                          )
                          pushed_count += 1
                          print(f"  [+] {relative_path}")
                      elif result[0] != checksum:
                          cursor.execute(
                              """UPDATE notes
                                 SET title = %s, content = %s, checksum = %s, modified_at = %s
                                 WHERE path = %s AND note_type = 'org-roam'""",
                              (title, content, checksum, modified_at, relative_path)
                          )
                          updated_count += 1
                          print(f"  [~] {relative_path}")

                  except Exception as e:
                      print(f"  [!] Error processing {note_file}: {e}")

          conn.commit()
          cursor.close()
          conn.close()

          print(f"\n✓ Push complete: {pushed_count} new, {updated_count} updated")


      def pull_notes():
          """Pull notes from database to local filesystem"""
          conn = get_db_connection()
          cursor = conn.cursor()

          pulled_count = 0
          updated_count = 0

          cursor.execute("SELECT path, title, content, note_type, checksum FROM notes ORDER BY modified_at DESC")

          for row in cursor.fetchall():
              path, title, content, note_type, db_checksum = row

              try:
                  if note_type == 'zk':
                      full_path = ZK_NOTES_DIR / path
                  elif note_type == 'org-roam':
                      full_path = ORGROAM_NOTES_DIR / path
                  else:
                      print(f"  [!] Unknown note type: {note_type}")
                      continue

                  full_path.parent.mkdir(parents=True, exist_ok=True)

                  if full_path.exists():
                      with open(full_path, 'r', encoding='utf-8') as f:
                          local_content = f.read()
                      local_checksum = compute_checksum(local_content)

                      if local_checksum != db_checksum:
                          with open(full_path, 'w', encoding='utf-8') as f:
                              f.write(content)
                          updated_count += 1
                          print(f"  [~] {path}")
                  else:
                      with open(full_path, 'w', encoding='utf-8') as f:
                          f.write(content)
                      pulled_count += 1
                      print(f"  [+] {path}")

              except Exception as e:
                  print(f"  [!] Error processing {path}: {e}")

          cursor.close()
          conn.close()

          print(f"\n✓ Pull complete: {pulled_count} new, {updated_count} updated")


      def sync_notes():
          """Perform bidirectional sync: push then pull"""
          print("=== Starting bidirectional sync ===\n")
          print("Phase 1: Pushing local changes to database...")
          push_notes()
          print("\nPhase 2: Pulling database changes to local...")
          pull_notes()
          print("\n=== Sync complete ===")


      def main():
          parser = argparse.ArgumentParser(description="Sync notes between local filesystem and PostgreSQL")
          parser.add_argument('action', choices=['push', 'pull', 'sync'],
                              help='Action to perform: push (local -> db), pull (db -> local), or sync (both)')

          args = parser.parse_args()

          if args.action == 'push':
              push_notes()
          elif args.action == 'pull':
              pull_notes()
          elif args.action == 'sync':
              sync_notes()


      if __name__ == '__main__':
          main()
    '';
  };

  # Systemd user service for notes sync
  systemd.user.services.notes-sync = {
    Unit = {
      Description = "Sync notes to PostgreSQL database via Tailscale";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${notesSync}/bin/notes-sync sync";
      Environment = "NOTES_DB_PASSWORD=\${NOTES_DB_PASSWORD}";
    };
  };

  # Systemd timer for automatic sync every 5 minutes
  systemd.user.timers.notes-sync = {
    Unit = {
      Description = "Sync notes every 5 minutes";
    };
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
