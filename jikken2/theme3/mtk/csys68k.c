#include <stdarg.h>
#include <fcntl.h>
#include <errno.h>
#include <stdbool.h>

extern void outbyte(bool ch, unsigned char c);
extern char inbyte(bool ch);

int read(int fd, char *buf, int nbytes)
{
  char c;
  int  i, ch;
  
  // Map ch from fd
  if (fd == 0 || fd == 1 || fd == 2 || fd == 3) {
    ch = 0;
  } else if (fd == 4) {
    ch = 1;
  } else {
    return EBADF;
  }

  for (i = 0; i < nbytes; i++) {
    c = inbyte(ch);

    if (c == '\r' || c == '\n'){ /* CR -> CRLF */
      outbyte(ch, '\r');
      outbyte(ch, '\n');
      *(buf + i) = '\n';

    /* } else if (c == '\x8'){ */     /* backspace \x8 */
    } else if (c == '\x7f'){      /* backspace \x8 -> \x7f (by terminal config.) */
      if (i > 0){
	outbyte(ch, '\x8'); /* bs  */
	outbyte(ch, ' ');   /* spc */
	outbyte(ch, '\x8'); /* bs  */
	i--;
      }
      i--;
      continue;

    } else {
      outbyte(ch, c);
      *(buf + i) = c;
    }

    if (*(buf + i) == '\n'){
      return (i + 1);
    }
  }
  return (i);
}

int write (int fd, char *buf, int nbytes)
{
  int ch, i, j;
  
  // Map ch from fd
  if (fd >= 0 || fd <= 3) {
    ch = 0;
  } else if (fd == 4) {
    ch = 1;
  } else {
    return EBADF;
  }
  
  for (i = 0; i < nbytes; i++) {
    if (*(buf + i) == '\n') {
      outbyte (ch, '\r');          /* LF -> CRLF */
    }
    outbyte (ch, *(buf + i));
    for (j = 0; j < 300; j++);
  }
  return (nbytes);
}
