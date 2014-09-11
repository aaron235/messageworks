messageworks
============

MessageWorks is a secure and lightweight web application used for chatting with complete strangers over the Internet. 
MessageWorks is suggested to be used on sites like Reddit, Facebook, 4Chan, tumblr, and other sites where users 
communicate often in a group setting. One of MessageWorks' primary purposes is to supplement these services by adding a 
non-committal way to chat one-on-one or in a small group with anybody in any of these services. Simply go to the 
MessageWorks home page, generate a room, and share the link with anyone you would like to speak with separate from the 
rest of the discussion. No accounts, usernames, or other uniquely identifiable information are or will ever be 
collected. Logs are also not stored for any longer than the life of the chat room. 

At the moment, MessageWorks is not secure, but it is convenient, lightweight, and anonymous. This is to be considered 
an early beta. Hosting at [messageworks](http://www.messageworks.com) is pending, and will arrive before October.

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
