#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// 1221151623 16.00 22.95 23.06 22.07 303.00 262.55 247.36 209.42 7.75 7.55 7.52 7.46

#define TRUE 1
#define FALSE 0
#define INSTANT 1

int
chomp_excl(char *line)
{
   char c;
   char *p;
   for (p = line; *p != '\n' && *p != '\0'; p++)
      ;
   if (*p == '\n')
      *p = '\0';
   return;
}

// @return FALSE if more input, TRUE if done
int
get_window_run (const int run_num, const int window_secs, const int sample_type, double x[], double y[], int *N, int* window, const int do_outfile)
{
   char outfile_name[26];
   FILE *outfile = NULL;
   unsigned long _window_start = 0;
   unsigned long curr_tstamp;
   unsigned long prev_tstamp = 0;
   float cpu_instant, cpu_five, cpu_ten, cpu_fifteen, tps_instant, tps_five, tps_ten, tps_fifteen;
   char line[99];
   *N = 0;
   while ( NULL != fgets(line,100,stdin)  )
   {

      chomp_excl(line);
      if (9 != sscanf(line,"%u %f %f %f %f %*f %*f %*f %*f %f %f %f %f",
            &curr_tstamp, &cpu_instant, &cpu_five, &cpu_ten, &cpu_fifteen, &tps_instant, &tps_five, &tps_ten, &tps_fifteen) )
      {
         fprintf (stderr, "Bad line: [%s]",line);
         continue;
      }
      if (0 == _window_start)
      {
         window[0] = curr_tstamp;
         _window_start = curr_tstamp;
      }
      if ((curr_tstamp - window[0]) > window_secs)
      {
         if ((NULL != outfile) && do_outfile) fclose(outfile);
         return FALSE;
      }
      if (NULL == outfile && do_outfile) {
         sprintf (outfile_name,"dat/split.run-%d.log",run_num);
         outfile = fopen(outfile_name,"a");
      }
      if (do_outfile) { fprintf(outfile,"%s\n",line); }
      window[1] = curr_tstamp;
      if (prev_tstamp > 0) {
         if ((curr_tstamp - prev_tstamp) < 5) {
            fprintf(stderr,"Window less than 5 seconds: [%d] to [%d]\n",prev_tstamp, curr_tstamp);
            if (do_outfile) fclose(outfile);
            return TRUE;
         }
         if ((curr_tstamp - prev_tstamp) > 300) {
            fprintf(stderr,"Window more than 300 seconds: [%d] to [%d]\n",prev_tstamp, curr_tstamp);
            if (do_outfile) fclose(outfile);
            return TRUE;
         }
      }
      prev_tstamp = curr_tstamp;
      switch (sample_type) {
        case 0:
          x[*N] = (double)cpu_instant;
          y[*N] = (double)tps_instant;
          break;
        case 5:
          x[*N] = (double)cpu_five;
          y[*N] = (double)tps_five;
          break;
        case 10:
          x[*N] = (double)cpu_ten;
          y[*N] = (double)tps_ten;
          break;
        case 15:
          x[*N] = (double)cpu_fifteen;
          y[*N] = (double)tps_fifteen;
          break;
        default:
          fprintf(stderr,"Bad sample_type [%d]\n", sample_type );
          exit(23);
      }
      *N = *N + 1;
   }
   if (do_outfile) fclose(outfile);
   return TRUE;
}

int
fit_linear (double* anal_results, double *x, double *y, int n)
{
   double cov00, cov01, cov11, chisq;
   gsl_fit_linear (x, 1, y, 1, n,
                   &(anal_results[0]), &(anal_results[1]), 
            &(anal_results[2]),&(anal_results[3]),&(anal_results[4]),&(anal_results[5] ) );
   return 0;
}

int
main (int argc, char *argv[])
{
   int window_secs = 60*30;
   int n;
   double *x;
   double *y;
   double anal_results[6] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
   int rc;
   int window[2];
   int done = 0;
   int run_num = 0;
   int x_y_size;
   int sample_type;

   if (3 != argc) {
      fprintf(stderr,"Bad args. Usage: [%s] run_size sample_type\n", argv[0]);
      return 17;
   }
   window_secs = atoi(argv[1]);
   if (window_secs < 60) {
      fprintf(stderr,"Cannot have runs of less than one minute: [%s]\n",argv[1]);
      return -1;
   }
   sample_type = atoi(argv[2]);

   //one measurement every 5 seconds (this is ensured by get_window_run())
   x_y_size = ((window_secs/5) + 10);
   x = (double *) calloc ( x_y_size, sizeof(double));
   y = (double *) calloc ( x_y_size, sizeof(double));
   while ( ! done ) {
      run_num++;
      n = 0;
      memset(x,(double)0,x_y_size);
      memset(y,(double)0,x_y_size);
      done = get_window_run(run_num,window_secs,sample_type,x,y,&n,window,0);
////      if ( (rc = fit_linear(anal_results,x,y,n)) < 0) {
if ( (rc = fit_linear(anal_results,y,x,n)) < 0) {
        fprintf(stderr,"Error.");
        return rc;
      }
////      printf ("%d :  best fit: TPS = %g + %g CPU, cov[00]=[%g],cov[01](=cov[10])=[%g],cov[11]=[%g], chi^2 = %g\n", window[0], anal_results[0], anal_results[1],
printf ("%d :  best fit: CPU = %g + %g TPS, cov[00]=[%g],cov[01](=cov[10])=[%g],cov[11]=[%g], chi^2 = %g\n", window[0], anal_results[0], anal_results[1],
            anal_results[2],anal_results[3],anal_results[4],anal_results[5] );
   }
   return 0;
}
