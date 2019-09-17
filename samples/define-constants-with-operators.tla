BinTypes == { "trash", "recycle" }
Items == [ type: BinTypes, size: 1..6 ]
SetsOfFour(set) == set \X set \X set \X set

(* --algorithm recycler
variables
  items \in SetsOfFour(Items);
  ...