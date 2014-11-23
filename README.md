airtimetcp
==========
Airtime Challenge #2

External Libraries:
GCDAsyncSocket
SSZipArchive

Architecture:
NetworkManager manages all the communicate stages and passes the data chunks to PackageProcessor
PackageProcessor holds all valid Packets object and combine them at the very end for zipping and emailing

Use:
Run it on device, wait for download completion and processing. Email zip file.
Use the given spec in the email to decode the sound.
