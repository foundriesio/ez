#!/bin/sh
#
# Copyright (c) 2017 Linaro Limited
# Copyright (c) 2017 Open Source Foundries
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

SCRIPT_VERSION="1.06"

# logging
LOG_LEVEL_ERROR=1
LOG_LEVEL_WARN=2
LOG_LEVEL_INFO=3
LOG_LEVEL_DEBUG=4
LOG_LEVEL_VERBOSE_DEBUG=5

# constants
CONTROLLER_PATH="/sys/kernel/debug/bluetooth/6lowpan_control"
CONFIG_FILE_DELIMITER="="
CONFIG_PATH="/etc/bluetooth/bluetooth_6lowpand.conf"
DAEMON_LOCK_PATH="/var/lock/bluetooth_6lowpand.lock"
MACADDR_REGEX="([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}"
MACADDR_REGEX_LINE="^${MACADDR_REGEX}$"
LOGLEVEL_REGEX="^[${LOG_LEVEL_ERROR}-${LOG_LEVEL_VERBOSE_DEBUG}]$"
BT_NODE_FILTER="Linaro"

# defaults
DEFAULT_HCI_INTERFACE="hci0"
DEFAULT_SCANNING_WINDOW=5
DEFAULT_SCANNING_INTERVAL=10
DEFAULT_DEVICE_JOIN_DELAY=1
DEFAULT_MAX_DEVICES=8
DEFAULT_LOG_LEVEL=$LOG_LEVEL_DEBUG

# TODO: Enforce maximums
MAX_SCANNING_WINDOW=30
MAX_SCANNING_INTERVAL=300


##
# CONFIG FUNCTIONS
##

# conf_find_value()
# description:
#   Match a pattern to an entry in the conf file and return the value
#   after the = sign.
# params:
#   1: pattern
#   2: default value
function conf_find_value {
	if [ -e "${CONFIG_PATH}" ]; then
		line=$(grep -m 1 "^${1}${CONFIG_FILE_DELIMITER}" ${CONFIG_PATH})
		if [ "${?}" -eq "0" ]; then
			echo "${line#${1}${CONFIG_FILE_DELIMITER}}"
		else
			echo "${2}"
		fi
	else
		echo "${2}"
	fi
}

# conf_check_pattern()
# description:
#   Check if the specified pattern is present in the conf file
# params:
#   1: pattern string to match
function conf_check_pattern {
	if [ -e "${CONFIG_PATH}" ]; then
		grep -q "^${@}" ${CONFIG_PATH}
		if [ "${?}" -eq "0" ]; then
			echo "1"
		else
			echo "0"
		fi
	else
		echo "0"
	fi
}

# Set option_loglevel early so that logging can be done
option_loglevel="$(conf_find_value "LOG_LEVEL" "${DEFAULT_LOG_LEVEL}")"

# write_log()
# description:
#   Write information to stdout according the specified log level
# params:
#   1: log level
#   2>: output text
function write_log {
	if [ "${option_loglevel}" -ge "${1}" ]; then
		shift
		echo "$(date +%F-%T) ${@}" >&2
	fi
}

# conf_add_entry()
# description:
#   Add a new entry to the conf file
# params:
#   1: entry to add
function conf_add_entry {
	if [ "$(conf_check_pattern ${@})" -eq "1" ]; then
		echo "0"
	else
		echo "${@}" >> ${CONFIG_PATH}
		echo "${?}"
	fi
}

# conf_remove_entry()
# description:
#   Remove a matching entry in the conf file
# params:
#   1: matching pattern to remove
function conf_remove_entry {
	# TODO: handle escape chars like "/"
	cmd="sed -i '/^${@}/d' ${CONFIG_PATH}"
	eval ${cmd}
	echo "${?}"
}

function print_help {
cat << END_OF_HELP_MARKER
GENERAL COMMAND LINE OPTIONS:
-ll    | --loglevel		: default log level output (values: 1 to 5)
-d     | --daemonize		: daemonize
-wl    | --use_whitelist	: use whitelist (not persistent for use with -d)
-igf   | --ignore_filter	: connect all beacons (for use with -d)
-hciif | --hci_interface	: specify an alternate to hci0 interface (for use with -d)
-lscon | --list_connections	: list current 6lowpan connections
-h     | --help			: display this help
-v     | --version		: display script version

COMMAND LINE OPTIONS FOR CONFIG FILE MANAGEMENT:
-wlon  | --whitelist_on		: enable whitelist
-wloff | --whitelist_off	: disable whitelist
-wladd | --whitelist_add	: add device to whitelist (format: ##:##:##:##:##:##)
-wlrm  | --whitelist_remove	: remove device from whitelist (format: ##:##:##:##:##:##)
-wlclr | --whitelist_clear	: clears all whitelist entries
-wlls  | --whitelist_list	: list the WL= entries in conf
-bladd | --blacklist_add	: add device to blacklist (format: ##:##:##:##:##:##)
-blrm  | --blacklist_remove	: remove device from blacklist (format: ##:##:##:##:##:##)
-blclr | --blacklist_clear	: clears all blacklist entries
-blls  | --blacklist_list	: list the BL= entries in conf

CONFIGURATION FILE ENTRIES:
SKIP_INIT	: skip bt 6lowpan initialization (Ex: SKIP_INIT=1)
LOG_LEVEL	: logging level (Ex: LOG_LEVEL=4)
HCI_INTERFACE	: alternate hci interface (Ex: HCI_INTERFACE=hci0)
SCAN_WIN	: scanning search window in seconds (Ex: SCAN_WIN=5)
SCAN_INT	: scanning interval in seconds (Ex: SCAN_INT=10)
JOIN_DELAY	: device join delay in seconds (Ex: JOIN_DELAY=1)
MAX_DEVICES	: maximum # of devices to join (Ex: MAX_DEVICES=9)
USE_WL		: use-whitelist (Ex: USE_WL=1)
WL		: whitelist device entry (Ex: WL=##:##:##:##:##:##)
BL		: blacklist device entry (Ex: BL=##:##:##:##:##:##)
END_OF_HELP_MARKER
}

# create_daemon_lock()
# description:
#   If running in daemon mode, create lock file
function create_daemon_lock {
	if [ "${option_daemonize}" -eq "1" ]; then
		touch ${DAEMON_LOCK_PATH}
		result="${?}"
		if [ "${result}" -ne "0" ]; then
			write_log ${LOG_LEVEL_ERROR} "ERROR: creating lock file ${result}"
			exit 1
		fi
	fi
}

# clear_daemon_lock()
# description:
#   If running in daemon mode, remove lock file. Don't return any kind
#   of error code as this is the last function that runs on exit.
function delete_daemon_lock {
	if [ "${option_daemonize}" -eq "1" ]; then
		if [ -e "${DAEMON_LOCK_PATH}" ]; then
			rm ${DAEMON_LOCK_PATH}
			result="${?}"
			if [ "${result}" -ne "0" ]; then
				write_log ${LOG_LEVEL_ERROR} "ERROR: deleting lock file ${result}"
			fi
		fi
	fi
}

# clean_up()
# description:
#   Clean up function executed when receiving a signal from trap (e.g. TERM)
function clean_up {
	delete_daemon_lock
	exit
}

# check_daemon_lock()
# description:
#   If running in daemon mode, check for a lock file
function check_daemon_lock {
	if [ -e "${DAEMON_LOCK_PATH}" ]; then
		echo "1"
	else
		echo "0"
	fi
}

# get_connected_list()
# description:
#   Return a list of connected BT addr:
#   Format: [##:##:##:##:##:##] [##:##:##:##:##:##] [##:##:##:##:##:##]
function get_connected_list {
	if [ -e "${CONTROLLER_PATH}" ]; then
		cat ${CONTROLLER_PATH} | cut -f1 -d" " | tr '[a-z]' '[A-Z]' | sed "s/.*/[&]/"
	fi
}

# connect_device()
# description:
#   Connect/disconnect a device with the 6lowpan controller
# params:
#   1: BT addr
#   2: connect flag (1=connect, 0=disconnect)
function connect_device {
	local __addr=${1}
	local __connect=${2}
	local __device_cmd

	if [ "${__connect}" == "1" ]; then
		__device_cmd="connect ${__addr} 2"
	else
		# TODO: Fix a kernel related bug where must use "1" as the
		# address type here or we get ENOENT returned from
		# get_l2cap_conn here:
		# https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/net/bluetooth/6lowpan.c?id=refs/tags/v4.9.9#n1088
		__device_cmd="disconnect ${__addr} 1"
	fi
	write_log ${LOG_LEVEL_DEBUG} "[PRE] ${__device_cmd} > ${CONTROLLER_PATH}"
	echo "${__device_cmd}" > ${CONTROLLER_PATH}
	if [ "${?}" -ne "0" ]; then
		write_log ${LOG_LEVEL_ERROR} "ERROR generated in connect_device: ${?}"
	fi
	write_log ${LOG_LEVEL_DEBUG} "[POST] ${__device_cmd} > ${CONTROLLER_PATH}"
}

# Set a shell trap event for when script exits to remove
# the daemon lock file (if needed)
trap "clean_up" INT TERM EXIT

# set running options
option_hci_interface="$(conf_find_value "HCI_INTERFACE" "${DEFAULT_HCI_INTERFACE}")"
option_ignore_filter="$(conf_find_value "IGNORE_FILTER" "0")"
option_use_whitelist="$(conf_find_value "USE_WL" "0")"
option_daemonize=0
option_timeout="$(conf_find_value "SCAN_WIN" "${DEFAULT_SCANNING_WINDOW}")"
option_interval="$(conf_find_value "SCAN_INT" "${DEFAULT_SCANNING_INTERVAL}")"
option_join_delay="$(conf_find_value "JOIN_DELAY" "${DEFAULT_DEVICE_JOIN_DELAY}")"
option_max_devices="$(conf_find_value "MAX_DEVICES" "${DEFAULT_MAX_DEVICES}")"
option_skip_init="$(conf_find_value "SKIP_INIT" "0")"

# parse arguments
if [ "${#}" -eq 0 ]; then
	print_help
	exit 0
fi

while [ "${#}" -gt 0 ]; do
	case "${1}" in
	# NOTE: -ll option should be first in command line
	# to debug option parsing
	"-ll" | "--loglevel")
		shift
		if ! echo "${1}" | grep -q -E "${LOGLEVEL_REGEX}"; then
			write_log ${LOG_LEVEL_ERROR} "Log level must be between ${LOG_LEVEL_ERROR} and ${LOG_LEVEL_VERBOSE_DEBUG}"
			exit 1
		fi
		option_loglevel="${1}"
		shift
		;;
	"-d" | "--daemonize")
		if [ "$(check_daemon_lock)" -eq "0" ]; then
			option_daemonize=1
			shift
		else
			write_log ${LOG_LEVEL_ERROR} "Daemon already running (lock file exists)"
			exit 1
		fi
		;;
	"-si" | "--skip_init")
		option_skip_init=1
		shift
		;;
	"-wl" | "--use_whitelist")
		option_use_whitelist=1
		shift
		;;
	"-igf" | "--ignore_filter")
		option_ignore_filter=1
		shift
		;;
	"-hciif" | "--hci_interface")
		shift
		option_hci_interface="${1}"
		shift
		;;
	"-lscon" | "--list_connections")
		echo "$(cat ${CONTROLLER_PATH} | cut -f1 -d' ' | tr '[a-z]' '[A-Z]')"
		exit "${?}"
		;;
	"-wlon" | "--whitelist_on")
		result=$(conf_add_entry "USE_WL=1")
		if [ "${result}" -ne "0" ]; then
			exit "${result}"
		fi
		shift
		;;
	"-wloff" | "--whitelist_off")
		result=$(conf_remove_entry "USE_WL=1")
		if [ "${result}" -ne "0" ]; then
			exit "${result}"
		fi
		shift
		;;
	"-wladd" | "--whitelist_add")
		shift
		__device="$(echo ${1} | tr '[:lower:]' '[:upper:]')"
		if echo "${__device}" | grep -q -E "${MACADDR_REGEX_LINE}"; then
			result=$(conf_add_entry "WL=${__device}")
			if [ "${result}" -ne "0" ]; then
				exit "${result}"
			fi
			shift
		else
			write_log ${LOG_LEVEL_ERROR} "Invalid BT address format.  Use ##:##:##:##:##:##"
			exit 1
		fi
		;;
	"-wlrm" | "--whitelist_remove")
		shift
		__device="$(echo ${1} | tr '[:lower:]' '[:upper:]')"
		if echo "${__device}" | grep -q -E "${MACADDR_REGEX_LINE}"; then
			result=$(conf_remove_entry "WL=${__device}")
			if [ "${result}" -ne "0" ]; then
				exit "${result}"
			fi
			if [ "${option_use_whitelist}" -eq "1" ]; then
				connected_list=$(get_connected_list)
				if [[ "${connected_list}" == *"[${__device}]"* ]]; then
					connect_device ${__device} 0
				fi
			fi
			shift
		else
			write_log ${LOG_LEVEL_ERROR} "Invalid BT address format.  Use ##:##:##:##:##:##"
			exit 1
		fi
		;;
	"-wlclr" | "--whitelist_clear")
		result=$(conf_remove_entry "WL=*")
		if [ "${result}" -ne "0" ]; then
			exit "${result}"
		fi
		shift
		;;
	"-wlls" | "--whitelist_list")
		if [ -e "${CONFIG_PATH}" ]; then
			grep "^WL=" ${CONFIG_PATH} | cut -f2 -d${CONFIG_FILE_DELIMITER}
			exit "${?}"
		else
			exit 0
		fi
		;;
	"-bladd" | "--blacklist_add")
		shift
		__device="$(echo ${1} | tr '[:lower:]' '[:upper:]')"
		if echo "${__device}" | grep -q -E "${MACADDR_REGEX_LINE}"; then
			result=$(conf_add_entry "BL=${__device}")
			if [ "${result}" -ne "0" ]; then
				exit "${result}"
			fi
			connected_list=$(get_connected_list)
			if [[ "${connected_list}" == *"[${__device}]"* ]]; then
				connect_device ${__device} 0
			fi
			shift
		else
			write_log ${LOG_LEVEL_ERROR} "Invalid BT address format.  Use ##:##:##:##:##:##"
			exit 1
		fi
		;;
	"-blrm" | "--blacklist_remove")
		shift
		__device="$(echo ${1} | tr '[:lower:]' '[:upper:]')"
		if echo "${__device}" | grep -q -E "${MACADDR_REGEX_LINE}"; then
			result=$(conf_remove_entry "BL=${__device}")
			if [ "${result}" -ne "0" ]; then
				exit "${result}"
			fi
			shift
		else
			write_log ${LOG_LEVEL_ERROR} "Invalid BT address format.  Use ##:##:##:##:##:##"
			exit 1
		fi
		;;
	"-blclr" | "--blacklist_clear")
		result=$(conf_remove_entry "BL=*")
		if [ "${result}" -ne "0" ]; then
			exit "${result}"
		fi
		shift
		;;
	"-blls" | "--blacklist_list")
		if [ -e "${CONFIG_PATH}" ]; then
			grep "^BL=" ${CONFIG_PATH} | cut -f2 -d${CONFIG_FILE_DELIMITER}
			exit "${?}"
		else
			exit 0
		fi
		;;
	"-v" | "--version")
		echo "${SCRIPT_VERSION}"
		exit 0
		;;
	"-h" | "--help" | *)
		print_help
		exit 0
		;;
	esac
done

if [ "${option_daemonize}" -eq "1" ]; then
	write_log ${LOG_LEVEL_DEBUG} "::: RUNTIME VALUES :::"
	write_log ${LOG_LEVEL_DEBUG} "HCI_INTERFACE=${option_hci_interface}"
	write_log ${LOG_LEVEL_DEBUG} "IGNORE_FILTER=${option_ignore_filter}"
	write_log ${LOG_LEVEL_DEBUG} "USE_WHITELIST=${option_use_whitelist}"
	write_log ${LOG_LEVEL_DEBUG} "TIMEOUT=${option_timeout}"
	write_log ${LOG_LEVEL_DEBUG} "INTERVAL=${option_interval}"
	write_log ${LOG_LEVEL_DEBUG} "JOIN_DELAY=${option_join_delay}"
	write_log ${LOG_LEVEL_DEBUG} "MAX_DEVICES=${option_max_devices}"
	write_log ${LOG_LEVEL_DEBUG} "SKIP_INIT=${option_skip_init}"
fi

# count_connected_devices()
# description:
#   This function uses the output of get_connected_list() to count how many
#   devices are currently connected
# params:
#   1: connected_device_list generated by get_connected_list()
function count_connected_devices {
	echo "${1}" | grep -o -E "\[${MACADDR_REGEX}\]" | wc -l
}

# find_ipsp_device()
# description:
#   This function loops for a timeout specified looking
#   for BT devices to connect to 6lowpan
# params:
#   1: timeout in seconds to look for devices to connect
function find_ipsp_device {
	local __timeout=${1}
	local __found_devices
	local __pid=0
	local __check_pid=0
	local __found_mac=0

	# Store the list of connect devices in upper case surrounded by []
	connected_list=$(get_connected_list)

	# check to see if we have max devices connected, if so return early
	__count_devices=$(count_connected_devices "${connected_list}")
	if [ "${__count_devices}" -ge "${option_max_devices}" ]; then
		return
	fi

	# Lines will start with MAC and then description broken by returns:
	# Return the first MAC which is followed by BT_NODE_FILTER match
	__lines=$(pylescan -i ${option_hci_interface} -c -t ${__timeout} -s)
	if [ "${?}" -ne "0" ]; then
		write_log ${LOG_LEVEL_ERROR} "ERROR generated during LE scan: ${?}"
		exit 1
	fi
	for __line in ${__lines}; do
		if echo "${__line}" | grep -q -E "${MACADDR_REGEX_LINE}"; then
			__found_devices=${__line}
			continue
		fi

		if [ -z "${__found_devices}" ]; then
			continue
		fi

		if [ "${option_ignore_filter}" -eq "1" ] ||
		   [ "${__line}" == "${BT_NODE_FILTER}" ]; then
			# Store the list of connect devices in upper case surrounded by []
			connected_list=$(get_connected_list)
			# check that this node isn't already connected
			if [[ "${connected_list}" == *"[${__found_devices}]"* ]]; then
				write_log ${LOG_LEVEL_VERBOSE_DEBUG} "ALREADY CONNECTED: ${__found_devices}"
				continue
			fi

			# check if max devices are already connected, if so abort connect loop
			__count_devices=$(count_connected_devices "${connected_list}")
			if [ "${__count_devices}" -ge "${option_max_devices}" ]; then
				write_log ${LOG_LEVEL_DEBUG} "MAX DEVICES CONNECTED (${__count_devices}) -- STOP ADDING"
				break
			fi

			# check whitelist
			if [ "${option_use_whitelist}" -eq "1" ] &&
			   [ "$(conf_check_pattern "WL=${__found_devices}")" -ne "1" ]; then
				write_log ${LOG_LEVEL_DEBUG} "IGNORING NODE (WL): ${__found_devices}"
				continue
			fi

			# check blacklist
			if [ "$(conf_check_pattern "BL=${__found_devices}")" -eq "1" ]; then
				write_log ${LOG_LEVEL_DEBUG} "IGNORING NODE (BL): ${__found_devices}"
				continue
			fi

			write_log ${LOG_LEVEL_INFO} "FOUND NODE: ${__found_devices}"
			connect_device ${__found_devices} 1

			# BUGFIX: waiting before continuing avoids a crash in 6lowpan
			sleep ${option_join_delay}
		fi

		__found_devices=""
	done
}

# ENTER daemon loop to connect Linaro FOTA BT devices
if [ "${option_daemonize}" -eq "1" ]; then
	create_daemon_lock

	if [ "${option_skip_init}" -eq "0" ]; then
		# INIT bluetooth modules
		modprobe bluetooth_6lowpan
		if [ "${?}" -ne "0" ]; then
			write_log ${LOG_LEVEL_ERROR} "ERROR generated while inserting module bluetooth_6lowpan: ${?}"
			exit 1
		fi
		sleep 1
	fi

	# Make sure 6lowpan_enable is always 1
	echo 1 > /sys/kernel/debug/bluetooth/6lowpan_enable
	if [ "${?}" -ne "0" ]; then
		write_log ${LOG_LEVEL_ERROR} "ERROR generated while enabling 6lowpan: ${?}"
		exit 1
	fi


	# reset hci interface
	hciconfig ${option_hci_interface} up
	if [ "${?}" -ne "0" ]; then
		write_log ${LOG_LEVEL_ERROR} "ERROR generated while bringing HCI interface ${option_hci_interface} up: ${?}"
		exit 1
	fi
	hciconfig ${option_hci_interface} reset
	if [ "${?}" -ne "0" ]; then
		write_log ${LOG_LEVEL_ERROR} "ERROR generated while resetting HCI interface ${option_hci_interface}: ${?}"
		exit 1
	fi

	while :; do
		find_ipsp_device ${option_timeout}
		sleep ${option_interval}
	done
fi
# EXIT daemon loop
