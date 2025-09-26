let loop_alignment_biplang (n_l : int) (n_r : int) (a_l : int array) (a_r : int array) (b_l : int array) (b_r : int array) (d_l : int array) (d_r : int array) =
  let i_l = ref (1) in
  let i_r = ref (1) in
  assert ((!i_l <= n_l));
  b_l.(!i_l) <- a_l.(!i_l);
  d_l.(!i_l) <- b_l.((!i_l - 1));
  i_l := (!i_l + 1);
  d_r.(1) <- b_r.(0);

  while (!i_l < n_l) do
    (*@ invariant ((!i_l < n_l)) <-> ((!i_r < (n_r - 1)))
        variant   n_l - !i_l
        invariant !i_r >= 0 && !i_l = !i_r + 1
        invariant b_l.(!i_r) = a_l.(!i_r)
        invariant b_l.(!i_r - 1) = b_r.(!i_r - 1) 
        invariant forall k. 1 <= k < !i_l -> d_l.(k) = d_r.(k) *)    
    b_l.(!i_l) <- a_l.(!i_l);    
    b_r.(!i_r) <- a_r.(!i_r);    
    d_l.(!i_l) <- b_l.((!i_l - 1));    
    d_r.((!i_r + 1)) <- b_r.(!i_r);
    i_l := (!i_l + 1);
    i_r := (!i_r + 1)
  done;

  b_r.(n_r) <- a_r.(n_r)
(*@ requires n_l >= 1 && n_l = n_r 
    requires Array.length a_l = n_l + 1 
    requires Array.length b_l = n_l + 1 
    requires Array.length d_l = n_l + 1 

    requires Array.length a_l = Array.length a_r
    requires Array.length b_l = Array.length b_r
    requires Array.length d_l = Array.length d_r

    requires forall k. 0 <= k < n_l -> a_l.(k) = a_r.(k)
    requires b_l.(0) = b_r.(0)
		
    ensures  forall k. 1 <= k < n_l -> d_l.(k) = d_r.(k) *)

