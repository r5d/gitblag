# gitblag

`gitblag` is a simple hook script to automatically send an email to
the readers whenever a new entry/essay/post is pushed to a
website/blog maintained using [git][git], the stupid content tracker.

The subject and the body of the email is slurped from the commit
message.

`gitblag` is based on the `post-receive-email` script found in the
contrib/hooks directory in the [Git SCM][git-source]'s source.

[git]: http://git-scm.com/
[git-source]: http://github.com/git/git

See *using gitblag* for info on how to install and use it.

## etymology

The name `gitblag` resulted from copulative compounding of two
obvious word stems -- `git` & `blag`.

The word `blag`, a mispronunciation of `blog`, AFAIK, (first) appeared
in the [xkcd comic][blag].

[blag]: http://xkcd.com/148/

## using gitblag

`gitblag` is meant to be used as a post-receive hook on a bare remote
git repository of a website/blog. This hook is invoked on the remote
repository when a `git push` happens on the local repository.

The `gitblag` script does two things:

+  Sends an email to the readers when it finds a specifically formatted
   `commit` (see 'Commit Message Format' section), on the `master`
   branch.

+  Checks out the latest version of the working tree.

For help setting up a website/blog maintained using git, read [Using
Git to manage a web site][git-website].

[git-website]: http://toroid.org/ams/git-website-howto

### installation

Get a copy.

    $ git clone http://rsiddharth.ninth.su/git/gitblag.git

Copy the script to the bare git repo of the website/blog.

    $ cd /path/to/your/bare/repo/wobsite.git

    $ cp /path/to/gitblag/src/gitblag.sh hooks/post-receive

    $ chmod 755 hooks/post-receive

Specify the location of the git maintained website/blog by changing
the value of `GIT_WORK_TREE` variable in the `hooks/post-receive`
script.

### configuration

1. Go to the remote bare git repo of the website/blog.

        $ cd /path/to/your/bare/repo/wobsite.git

2. Set up the mailing list to which the script should send emails to.

        $ git config --local --add hooks.mailinglist yourblag@list.tld

   Or list the recipients' (the readers) email IDs, one email ID per
   line, in a plain text file and inform git about it.

        $ git config --local --add hooks.recipientlist /path/to/readerlist.txt

3. Set up the email prefix. All emails will have their subjects
   prefixed with this prefix &mdash; `[Mailing List Prefix]` &mdash; if
   emailprefix is not set.

        $ git config --local --add hooks.emailprefix "[ BLAG PREFIX ]"

4. Set up the mailing list footer. Edit the `description` file in the
   bare git repo.

        $ editor description

5. To set a custom `From` field, the hooks.envelopesender option needs
   to be set.

        $ git config --local --add hooks.envelopesender from@address.tld

### commit message format

+ Start the commit message with `[NEW POST]` followed by text that
will be used as the subject of the email.

+ Leave a blank line.

+ Write the body of the email.

See the `sample-commit-msg.txt` file.

## license

`gitblag` is licensed under the GNU General Public License version 3
or later. See COPYING for the full text of the license.

## contact

 rsiddharth `<rsiddharth@ninthfloor.org>`
