import math

class Stats_Stream:
    def __init__(self):
        self._n =0
        self._min=None
        self._max=None
        self._M2=0
        self._mean=0
        
    def add_item (self,x):
        self._n = self._n + 1
        x=float(x)
        if self._n == 1 :
            self._min=x
            self._max=x
        else:
            if self._min > x:
                self._min = x
            if self._max < x:
                self._max = x
            
        delta = x - self._mean
        self._mean = self._mean + delta/self._n
        self._M2 = self._M2 + delta*(x - self._mean)

    def SD(self):
        if (self._n > 1):
            return (math.sqrt(self._M2/(self._n - 1)))
        else:
            return 0
    
    def N(self):
        return (self._n)
        
    def Mean(self):
        return (self._mean)
        
    def Min(self):
        return (self._min)
        
    def Max(self):
        return (self._max)
        
    def __str__(self):
        return "Stream_SD N: {0}, Mean: {1}, SD: {2}, Min: {3}, Max: {4}".format(self.N(),self.Mean(),self.SD(),self.Min(),self.Max()) 
