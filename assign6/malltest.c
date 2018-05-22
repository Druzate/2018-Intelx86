#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "malloc3140.h"

int main() {
   void *p1 = l_malloc(80);
   void *p2 = l_malloc(16);
   l_free(p1);
   p1 = l_malloc(8);
   void *p3 = l_malloc(16);
   l_free(p1);
   l_free(p3);
}

/* various other tests performed and commented out:
        void *p1 = l_malloc(20);
        void *p2 = l_malloc(32);
        void *p3 = l_malloc(10);
        
        //******************

        void *p1 = l_malloc(20);
        void *p2 = l_malloc(132000);
        
        //******************

        void *p1 = l_malloc(20);
        void *p2 = l_malloc(282000);
        
        //******************
        
        void *p1 = l_malloc(20);
        void *p2 = l_malloc(16);
        l_free(p1);
        
        //******************
        
        void *p1 = l_malloc(20);
        void *p2 = l_malloc(16);
        l_free(p1);
        l_free(p2);
        
        //******************
        
        void *p1 = l_malloc(40);
        void *p2 = l_malloc(16);
        l_free(p1);
        p1 = l_malloc(8);
*/