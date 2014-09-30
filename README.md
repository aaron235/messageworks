messageworks
============

MessageWorks is a secure and lightweight web application used for chatting with strangers over the internet. 

MessageWorks can be used alongside services like Reddit, Facebook, 4Chan, tumblr, and other social networks. One of MessageWorks' primary purposes is to supplement these services by adding a non-committal way to chat one-on-one or in a small group with anybody from any of these services. 

Simply go to the MessageWorks home page, make a room, and share the link with anyone you would like to invite. No accounts, usernames, or other uniquely identifiable information are or will ever be collected. When the room dies, message history logs are removed as well.

MessageWorks is not yet fully secure, but it is convenient, lightweight, and anonymous. The current code base should be considered an early beta.

MessageWorks uses the following Perl modules:

*	[MongoDB](https://metacpan.org/pod/MongoDB)
*	[Mojolicious](https://metacpan.org/release/Mojolicious)
*	[DateTime](https://metacpan.org/pod/DateTime)

MessageWorks also requires some of the following system packages:

*	MongoDB (this webapp expects to find an authentication-free server on the Mongo default port)
*	Morbo (this is a utility for running webservers included with Mojolicious)
*	Perl 5.10 or higher (theoretically this could work on any version of Perl 5, but this is the oldest version we have 
tested on)

The server has been run on Debian Jessie, Debian Wheezy, and Arch Linux, but it is written with Debian Wheezy amd64 in 
mind.
