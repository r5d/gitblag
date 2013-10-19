#!/bin/sh
#
# Copyright 2013 rsiddharth <rsiddharth@ninthfloor.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# This program is based on the post-receive-email hook script in the
# contrib/hooks directory in the Git SCM's source.
#
# The post-receive-mail hook script is Copyright (c) 2007 Andy Parkins
#
# Config
# ------
# hooks.mailinglist
#   This is the list that all pushes will go to; leave it blank to not send
#   emails for every ref update.
# hooks.envelopesender
#   If set then the -f option is passed to sendmail to allow the envelope
#   sender address to be set
# hooks.emailprefix
#
#   All emails have their subjects prefixed with this prefix, or
#   "[Mailing List Prefix]" if emailprefix is unset, to aid filtering
#
# Notes
# -----
# All emails include the headers "X-Git-Refname", "X-Git-Oldrev",
# "X-Git-Newrev", and "X-Git-Reftype" to enable fine tuned filtering and
# give information for debugging.
#

# ---------------------------- Functions

# Function to prepare for email generation. This whether an email
# should even be generated.

prep_for_email()
{
	# --- Arguments
	oldrev=$(git rev-parse $1)
	newrev=$(git rev-parse $2)
	refname="$3"

    # --- Interpret
	# 0000->1234 (create)
	# 1234->2345 (update)
	# 2345->0000 (delete)
	
	if expr "$newrev" : '0*$' >/dev/null
	then
		# change_type is delete
		# Don't have to send an email.
		return 1
	fi
	
	# --- Get the revision type
	newrev_type=$(git cat-file -t $newrev 2> /dev/null)
	
	if [ $newrev_type = "commit" ]; then
		
		if [ $refname = "refs/heads/master" ]; then

			# iterate through all the new commits introduced by the
			# git push
			for rev in $(git rev-list $oldrev..$newrev)
			do
				commit_msg=$(git cat-file -p $rev | sed '1,/^$/d')
				
				if expr "$commit_msg" : "^\[NEW POST\].*$" >/dev/null
				then
				# Send email.
					return 0
				fi
			done
			
		fi

	fi
	
	# Don't have to send email.
	return 1
}

generate_email()
{
	generate_email_header
		
	generate_email_body

	generate_email_footer
}

generate_email_header()
{

	# strip off the [NEW POST] from the message:
	commit_msg=$(echo "$commit_msg" | sed 's/\[NEW POST\]//g')

	subject=$(echo "$commit_msg" | sed '1q')

	# --- Email (all stdout will be the email)
	# Generate header
	cat <<-EOF
	To: $recipients
	Subject: ${emailprefix} $subject
	X-Git-Refname: $refname
	X-Git-Reftype: $refname_type
	X-Git-Oldrev: $oldrev
	X-Git-Newrev: $newrev
	Auto-Submitted: auto-generated

	EOF
}

generate_email_footer()
{
	SPACE=" "
	cat <<-EOF


	--${SPACE}
	${listfooter}
	EOF
}

generate_email_body()
{
	body=$(echo "$commit_msg" | sed '1,/^$/d')
	
	echo "$body"
}

send_mail()
{
	if [ -n "$envelopesender" ]; then
		/usr/sbin/sendmail -t -f "$envelopesender"
	else
		/usr/sbin/sendmail -t
	fi
}

# ---------------------------- main()

# --- Config
# Set GIT_DIR either from the working directory, or from the environment
# variable.
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [ -z "$GIT_DIR" ]; then
	echo >&2 "fatal: post-receive: GIT_DIR not set"
	exit 1
fi

listfooter=$(sed -ne '1p' "$GIT_DIR/description" 2>/dev/null)
# Check if the description is unchanged from it's default, and shorten it to
# a more manageable length if it is
if expr "$listfooter" : "Unnamed repository.*$" >/dev/null
then
	listfooter="Mailing list footer. To change modify .git/description at remote repo."
fi

recipients=$(git config hooks.mailinglist)
envelopesender=$(git config hooks.envelopesender)
emailprefix=$(git config hooks.emailprefix || echo '[Mailing List Prefix]')

# --- Main loop
# Allow dual mode: run from the command line just like the update hook, or
# if no arguments are given then run as a hook script
if [ -n "$1" -a -n "$2" -a -n "$3" ]; then
	# Output to the terminal in command line mode - if someone wanted to
	# resend an email; they could redirect the output to sendmail
	# themselves
	prep_for_email $2 $3 $1 && PAGER= generate_email
else
	while read oldrev newrev refname
	do
		prep_for_email $oldrev $newrev $refname || continue
		generate_email | send_mail
	done
fi

GIT_WORK_TREE=/absolute/path/to/the/website git checkout -f