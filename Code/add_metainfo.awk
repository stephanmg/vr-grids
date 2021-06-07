{
   n=split($0,a,","); 
   for (i=1; i<=n; i++) {
      m=split(a[i], b, ":"); 
      if (b[1] == "\"" k "\"") {
         print(b[2])
      }
   }
}
