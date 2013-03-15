#include "sha1.cu"

#define IPAD 0x36363636
#define OPAD 0x5c5c5c5c

__device__ void 
memxor (void * dest, const void * src,size_t n)
{
  int rest = n%4;
  n = n/4;
  const int * s = (int*)src;
  int *d = (int*)dest;
  const char * s2 = (char*)src+4*n;
  char *d2 = (char*)dest+4*n;
  for (; n > 0; n--)
    *d++ ^= *s++;
  for (; rest > 0; rest--)
    *d2++ ^= *s2++;
}
__device__ void
hmac_sha1 (const void * key, uint32_t keylen,
           const void *in, uint32_t inlen, void *resbuf, struct globalChars *chars)
{
  struct sha1_ctx inner;
  struct sha1_ctx outer;

  sha1_init_ctx (&inner);
  cudaMemsetDevice (chars->block, IPAD, sizeof (chars->block));
  memxor(chars->block, key, keylen);
  sha1_process_block (chars->block, 64, &inner);
  sha1_process_bytes (in, inlen, &inner);
  sha1_finish_ctx (&inner, chars->innerhash);
  
  /* Compute result from KEY and INNERHASH.  */
  sha1_init_ctx (&outer);
  cudaMemsetDevice (chars->block, OPAD, sizeof (chars->block));
  memxor(chars->block, key, keylen);
  sha1_process_block (chars->block, 64, &outer);
  sha1_process_bytes (chars->innerhash, 20, &outer);   
  sha1_finish_ctx (&outer, resbuf);
}
