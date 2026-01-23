#!/usr/bin/env bash
# Test script to simulate distrobox init_hooks escaping
# The key insight: distrobox wraps init_hooks in single quotes like: -- '${container_init_hook}'

echo "=== Testing init_hooks escaping ==="
echo ""

# Our INI file value (what we write in distrobox.ini)
# Test 1: Original with single quotes - THIS BREAKS
test1="echo '\${USER} ALL = NOPASSWD: ALL' > /etc/sudoers.d/\${USER}"
echo "Test 1 (single quotes inside - BREAKS):"
echo "  INI value: init_hooks=\"$test1\""
echo "  Command generated: -- '$test1'"
echo "  Trying eval..."
eval "echo 'Command would be: -- '\"'\"'$test1'\"'\"''"
echo ""

# Test 2: Using double quotes inside
test2='echo "${USER} ALL = NOPASSWD: ALL" > /etc/sudoers.d/${USER}'
echo "Test 2 (double quotes inside):"
echo "  INI value: init_hooks=\"$test2\""
echo "  Command generated: -- '$test2'"
echo "  Trying eval..."
container_init_hook="$test2"
eval "echo 'Testing: -- '\"'\"'$container_init_hook'\"'\"''"
echo ""

# Test 3: No quotes at all (will this work?)
test3='echo ${USER} ALL = NOPASSWD: ALL > /etc/sudoers.d/${USER}'
echo "Test 3 (no quotes):"
echo "  INI value: init_hooks=\"$test3\""
echo ""

# Test 4: Escaped single quotes
test4="echo '\''\\${USER} ALL = NOPASSWD: ALL'\\'' > /etc/sudoers.d/\\${USER}"
echo "Test 4 (escaped single quotes):"
echo "  INI value: init_hooks=\"$test4\""
echo ""

# Test 5: Using printf to avoid quote issues
test5='printf "%s ALL = NOPASSWD: ALL\n" "${USER}" > /etc/sudoers.d/${USER}'
echo "Test 5 (printf approach):"
echo "  INI value: init_hooks=\"$test5\""
echo ""

echo "=== Actual simulation of distrobox behavior ==="
echo ""

# Simulate what distrobox does with the value
simulate_distrobox() {
    local ini_value="$1"
    local description="$2"

    echo "Testing: $description"
    echo "  INI: init_hooks=\"$ini_value\""

    # This is how distrobox generates the command
    local cmd="echo 'init hook would run:' -- '$ini_value'"

    echo "  Generated cmd: $cmd"
    echo "  Eval result:"
    if eval "$cmd" 2>&1; then
        echo "  ✓ SUCCESS"
    else
        echo "  ✗ FAILED"
    fi
    echo ""
}

# Run simulations
simulate_distrobox 'echo "${USER} ALL = NOPASSWD: ALL" > /etc/sudoers.d/${USER}' "double quotes"
simulate_distrobox "echo \"\${USER} ALL = NOPASSWD: ALL\" > /etc/sudoers.d/\${USER}" "escaped double quotes"
simulate_distrobox 'printf "%s ALL = NOPASSWD: ALL\n" ${USER} > /etc/sudoers.d/${USER}' "printf no quotes on USER"
