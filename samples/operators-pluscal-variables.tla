(* --algorithm recycler
variables
    capacity = [ trash |-> 10, recycle |-> 10 ],
    bins = [ trash |-> {}, recycle |-> {} ],
    count = [ trash |-> 0, recycle |-> 0 ];

define
  NoBinOverflow ==
    capacity.trash >= 0 /\ capacity.recycle >= 0
  CountsMatchUp =
    /\ Len(bins.trash) = count.trash
    /\ Len(bins.recycle) = count.recycle
end define;

\* macros...