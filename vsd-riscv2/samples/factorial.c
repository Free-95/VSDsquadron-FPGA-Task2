#include <stdio.h>

int factorial(int n){
    if (n == 0)
        return 1;
    else
        return n * factorial(n - 1);
}

int main(){

  printf("Enter a number to compute its factorial: ");
  
  // FORCE the buffer to print to screen immediately
  fflush(stdout);
  
  int n, fact;
  scanf("%d", &n);

  fact = factorial(n);
  printf("Factorial of %d is %d \n", n, fact);
  return 0;
}
