variables
  capacity \in [trash: 1..10, recycle: 1..10],
  item \in [type: {"trash", "recycle"}, size: 1..6],
  items \in item \X item \X item \X item;