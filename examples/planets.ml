open Tsd
open List

type planet = 
    { id : int;
      mass : float;
      pos : float * float * float;
      speed : float * float * float; } 

(* Constants *)
let g = 6.67
let dt = 0.1
let size_x = 1280 
let size_y = 720 

(* Auxiliary functions *)
let random_speed () =
  ((Random.float 100.0) -. 50.0,
   (Random.float 100.0) -. 50.0,
   (Random.float 100.0) -. 50.0)

let new_pos x y =
  let max_x_2 = size_x / 2 in
  let max_y_2 = size_y / 2 in
  (float_of_int (x - max_x_2),
   float_of_int (y - max_y_2), 
   (Random.float 200.0) -. 100.0)

let random_pos () =
  let x = ((Random.int 200) - 100) + (size_x) / 2 in
  let y = ((Random.int 200) - 100) + (size_y) / 2 in
  new_pos x y

let distance2 (x,y,z) (x',y',z') = 
	(x' -. x)*.(x' -. x)
    +. (y' -. y)*.(y' -. y)
    +. (z' -. z)*.(z' -. z) 

let distance pos1 pos2 = sqrt (distance2 pos1 pos2) 

let new_planet n = 
	{ id = n;
	  mass = 1.0;
	  pos = random_pos (); 
	  speed = random_speed(); } 

(* --------------------------------------------------------------------- *)

(* Console window *)
(* modified by Steven *)
let update_display all = 
  let all = peek all in 
  List.iter 
    (fun p -> 
    	let { id=id; pos=(x,y,z) } = p in 
        print_string 
          ("id: "^string_of_int id^", x: "^string_of_float x^", y: "^string_of_float y^", z: "^string_of_float z);
        print_newline()) all

(* --------------------------------------------------------------------- *)
(* planet definition *)
(* modified by Steven *)
let compute_pos =
  let force 
        { id=id1; pos= (x1,y1,z1) as pos1; mass=m1 } 
        { id=id2; pos= (x2,y2,z2) as pos2; mass=m2 } =
    let d2 = distance2 pos1 pos2 in
    let d = sqrt d2 in
    if (id1 <> id2 && d <> 0.0) then 
      let  f12 = g *. (m1 *. m2) /. d2 in
      (f12 *. (x2 -. x1) /. d,
       f12 *. (y2 -. y1) /. d,
       f12 *. (z2 -. z1) /. d)
    else
      (0.0, 0.0, 0.0)
  in
  fun ({ mass=m1; pos=(x,y,z); speed=(x',y',z') } as me) all ->
    let fx, fy, fz = 
      (List.fold_left 
   (fun (fx,fy,fz) p -> 
     let x,y,z = force me p in
     (fx +. x), 
     (fy +. y), 
     (fz +. z)) 
   (0.0, 0.0, 0.0) 
   all)
    in
    let (sx, sy, sz) as speed = 
      (x' +. (fx /. m1) *. dt, (* modified by Steven *)
       y' +. (fy /. m1) *. dt,
       z' +. (fz /. m1) *. dt)
    in
    let pos = (x +. sx *. dt,
         y +. sy *. dt,
         z +. sz *. dt)
    in
    { id = me.id;
      mass = me.mass;
      pos = pos;
      speed = speed; }

let rec create_planets n = 
	match n with
	| 0 -> []
	| n -> new_planet n :: create_planets (n - 1) 

let _ = 
  let n = 100 in 
  let total_step = 1000 in 
	let all = lift (create_planets n) in 
	let sun = {id=0;mass=30000.0;pos=(0.0,0.0,0.0);speed=(0.0,0.0,0.0)} in
	let all = cell [%dfg (lift cons) (lift sun) all] in 
  all <~ [%dfg (lift map) (fun x -> (lift compute_pos) x all) all];
	for i = 1 to total_step do
		step();
		update_display all
	done