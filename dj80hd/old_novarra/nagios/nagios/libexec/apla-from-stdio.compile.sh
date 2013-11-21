export LD_LIBRARY_PATH=/usr/local/lib/   #has libgsl.a and libgslcblas.a
gcc -I/usr/local/include/gsl -lgsl -lgslcblas -o apla-from-stdio apla-from-stdio.c
