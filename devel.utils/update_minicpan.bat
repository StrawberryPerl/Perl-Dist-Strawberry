rem call minicpan -l z:\_cpan-mirror -x -f -r http://cpan.mirror.dkm.cz/pub/CPAN/
rem call minicpan -l z:\_cpan-mirror -x -f -r http://archive.cs.uu.nl/mirror/CPAN/
rem call minicpan -l z:\_cpan-mirror -x -f -r http://mirrors.nic.cz/CPAN/
call minicpan -l z:\_cpan-mirror -x -f -r http://ftp.hawo.stw.uni-erlangen.de/CPAN/ -c CPAN::Mini::Devel
pause