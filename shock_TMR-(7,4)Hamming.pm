ctmc

//-------------------------------------------------------------------
// TMR-(7,4)Hamming Mode

// Observatation Time
const double T;

const double shockrate1;// Rate of type I shock
const double shockrate2;// Rate of type II shock
const double shockrate3;// Rate of type III shock

const double bit1 ; // Failure rate of a bit (s = 1)
const double bit2 ; // Failure rate of a bit(s = 2)
const double bit3 ; // Failure rate of a bit (s = 3)

const double n; // the bit number of words
const double read; // read rate
const double repair; // repair rate


// The Mixed Extreme Run Degraded model (MERD-Shock model)
module CRshock
                       // ns is the cumulative number of continuous shocks when the system is at s-level  
    n2:[0..6] init 0;  // st = 2,l2 = 6    
    n1:[0..3] init 0;  // st = 1,l1 = 3
    n0:[0..2] init 0;  // st = 0,l0 = 1 
    st:[0..2] init 2;  // The ability of the system to resist a continuous number of Type-II shocks

    // st = 2
    [] st = 2 & n2 < 5 -> shockrate2:(n2'= n2 + 1);// When a type II shock occurs and n2 < 5, state n2 transfer to n2 + 1
    [] st = 2 & n2 < 3 -> shockrate1:(n2'= 0);//  When a type I shock occurs and n2 < 3, n2 will be reset 0
    [] st = 2 & (n2 >= 3 & n2 < 6) -> shockrate1:(n1'= 0) & (st'= 1);// When a type I shock occurs and 3=<n2<6, then st = 1, n1 = 0
    [Alldown] st = 2 & n2 = 5 -> shockrate2:(n2'= 6); // When n2 = 5, a type II shock occurs,then the system will fail completely because the n2 = l2

    // st = 1
    [] st = 1 & n1 <= 1 -> shockrate1:(n1'= 0) + shockrate2:(n1'= n1 + 1);
    [] st = 1 & n1 = 2 -> shockrate1:(n0'= 0)&(st'= 0);
    [Alldown] st = 1 & n1 = 2 -> shockrate2:(n1'= 3);

    // st = 0
    [] st = 0 & n0 = 0 -> shockrate1:(n0'= 0);
    [Alldown] st = 0 & n0 = 0 -> shockrate2:(n0'= 1);

    // Alldown - Occurrence of extreme shock (type III)
    [Alldown] st = 2 & (n2 >= 0 & n2 != 6) -> shockrate3:(n2'= 6);
    [Alldown] st = 1 & (n1 >=0 & n1!= 3) -> shockrate3:(n1'= 3);
    [Alldown] st = 0 & (n0 >= 0 & n0 != 1) -> shockrate3:(n0'= 1);
endmodule


// The Design Mode
// TMR-£¨7.4£©Hamming Mode
module TMR74HAMMING

    s:[0..15] init 0;  // s = 0:(0,0,0)
			// s = 1:(0,0,1)
			// s = 2:(0,1,1)
			// s = 3:(1,1,1)
			// s = 4:(0,0,2)
			// s = 5:(0,1,2)
			// s = 6:(1,1,2)
			// s = 7:(0,0,3C)
			// s = 8:(0,0,3N)
			// s = 9:(0,1,3C)
			// s = 10:(0,1,3N)
			// s = 11:(1,1,3C)
			// s = 12:(1,1,3N)
			// s = 13:(2,2,0)
			// s = 14:(2,2,1)

    [] s = 0 -> st = 2? 3*n*bit1:st = 1 ? 3*n*bit2:3*n*bit3:(s'= 1);
    [] s = 1 -> st = 2? 2*n*bit1:st = 1 ? 2*n*bit2:2*n*bit3:(s'= 2);
    [] s = 1 -> st = 2? (n-1)*bit1:st = 1 ? (n-1)*bit2:(n-1)*bit3:(s'= 4);
    [] s = 2 -> st = 2? n*bit1:st = 1 ? n*bit2:n*bit3:(s' = 3);
    [] s = 2 -> st = 2? 2*(n-1)*bit1:st = 1? 2*(n-1)*bit2: 2*(n-1)*bit3:(s'= 5);
    [] s = 3 -> st = 2? 3*(n-1)*bit1:st = 1? 3*(n-1)*bit2: 3*(n-1)*bit3:(s'= 6);

    [] s >= 0 & s <= 3 -> read:(s'= 0); //state(x1, x2, x3)(x1<=1,x2<=1,x3<=1) ---> (0,0,0)

    [] s = 4 -> st = 2? bit1:st = 1 ? bit2: bit3:(s' = 7);
    [] s = 4 -> st = 2? (n-3)*bit1:st = 1? (n-3)*bit2:(n-3)*bit3:(s'= 8);
    [] s = 4 -> st = 2? 2*n*bit1:st = 1? 2*n*bit2:2*n*bit3:(s'= 5);
    [] s = 5 -> st = 2? bit1:st = 1? bit2: bit3:(s' = 9);
    [] s = 5 -> st = 2? (n-3)*bit1:st = 1 ?(n-3)*bit2:(n-3)*bit3:(s'= 10);
    [] s = 5 -> st = 2? (n-1)*bit1:st = 1 ? (n-1)*bit2:(n-1)*bit3:(s'= 13);
    [] s = 5 -> st = 2? n*bit1:st = 1?n*bit2:n*bit3:(s'= 6);
    [] s = 6 -> st = 2? 2*(n-1)*bit1:st = 1? 2*(n-1)*bit2:2*(n-1)*bit3:(s'= 14);
    [] s = 6 -> st = 2? bit1:st = 1?bit2:bit3:(s'= 11);
    [] s = 6 -> st = 2? (n-3)*bit1:st = 1?(n-3)*bit2:(n-3)*bit3:(s'= 12);

    [] s = 4 | s = 5 | s = 6 -> read:(s'= 4); //state(x1, x2, x3)(x1<=1,x2<=1,x3>=2) ---> (0,0,x3)

    [] s = 7 -> st = 2? 2*n*bit1:st = 1?2*n*bit2:2*n*bit3:(s'= 9);
    [] s = 8 -> st = 2? 2*n*bit1:st = 1?2*n*bit2:2*n*bit3:(s'= 10);
    [] s = 9 -> st = 2? n*bit1:st = 1? n*bit2:n*bit3:(s'= 11);
    [] s = 10 ->st = 2? n*bit1:st = 1? n*bit2:n*bit3:(s'= 12);

    [] s = 7 | s = 9 | s = 11 -> read:(s'= 7); // state(x1, x2, x3)(x1<=1,x2<=1,x3>=2) ---> (0,0,x3)
    [] s = 8 | s = 10 | s = 12 -> read:(s'= 8);// state(x1, x2, x3)(x1<=1,x2<=1,x3>=2) ---> (0,0,x3)

    [] s >=4 & s<= 12 -> repair:(s'= 0);//repair

    [] s = 13 -> st = 2? n*bit1:st = 1? n*bit2:n*bit3:(s' = 14);

    [] s = 14 ->read:(s' = 13);// state(x1,2,2) ---> (0,2,2)

    [] s = 13 ->repair:(s'= 0);//repair
    [] s = 14 ->repair:(s'= 0);//repair

    [Alldown] true ->(s' = 15);
endmodule

// The system is operational
formula up = (n2!=6 & n1!=3 & n0!=1)&(s<=12);
// The system temporarily fails and can still be reset through the scrubbing strategy
formula repair_down =(n2!=6 & n1!=3 & n0!=1)&(s = 13 |s = 14);
// Due to the occurrence of run shock or extreme shock, the system permanently fails
formula down = (n2 = 6|n1 = 3|n0 =1)|(s = 13|s = 14|s = 17);

label "up" = (n2!= 6 & n1!= 3 & n0!= 1)&(s<=12);
label "repair_down"=(n2!=6 & n1!=3 & n0!=1)&(s = 13 |s = 14);
label "down" = (n2 = 6|n1 = 3|n0 = 1)|(s = 13|s = 14|s = 17);

// the system is operational
rewards "up"
    up: 1;
    repair_down:0;
    down:0;
endrewards