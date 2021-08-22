ctmc

//-------------------------------------------------------
// TMR-Scrub Mode

// Observatation Time
const int T; 

// Scrub interval
const double t;
// Scrub rate
const double miu = 1/(3600*t);

const double shockrate1;// Rate of type I shock 
const double shockrate2;// Rate of type II shock
const double shockrate3;// Rate of type III shock

const double rate1 ; // SEU rate(s = 1)
const double rate2 ; // SEU rate(s = 2)
const double rate3 ; // SEU rate(s = 3)


//The Mixed Extreme Run Degraded model (MERD-Shock model) 
module CRshock
                       // ns is the cumulative number of continuous shocks when the system is at s-level
    n2:[0..6] init 0;  // st = 2,l2 = 6
    n1:[0..3] init 0;  // st = 1,l1 = 3
    n0:[0..1] init 0;  // st = 0,l0 = 1
    st:[0..2] init 2;  // The ability of the system to resist a continuous number of Type-II shocks

    // st = 2
    [] st = 2 & n2 < 5 -> shockrate2:(n2'= n2 + 1); // When a type II shock occurs and n2 < 5, state n2 transfer to n2 + 1
    [] st = 2 & n2 < 3 -> shockrate1:(n2'= 0); // When a type I shock occurs and n2 < 3, n2 will be reset 0
    [] st = 2 & (n2 >= 3 & n2 < 6) -> shockrate1:(n1'= 0) & (st'= 1); // When a type I shock occurs and 3=<n2<6, then st = 1, n1 = 0
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
module Model
    
    // s = 3 : all the three modules are in good condition
    // s = 2 : SCU has occurred
    // s = 1 : MCU has occurred
    // s = 0 : system enters the absorption state because of cumulative failure shock or extreme failure shock.
    s:[0..3] init 3;

    // the ratio of MCU and SCU rate = 0.01
    [] s = 3 -> st = 2? 3*0.99*rate1: st = 1? 3*0.99* rate2:  3*0.99*rate3: (s'= 2); 
    [] s = 3 -> st = 2? 3*0.01*rate1: st = 1? 3*0.01*rate2: 3*0.01*rate3: (s'= 1);
    [] s = 2 -> st = 2? 2*0.99*rate1: st = 1? 2*0.99*rate2: 2*0.99*rate3: (s'= 1);
    [] s = 2 -> st = 2? 0.01*rate1: st = 1? 0.01*rate2: 0.01*rate3: (s'= 1);

    // Scrubbing
    [] s = 3 -> miu:(s'= 3);
    [] s = 2 -> miu:(s'= 3);
    [] s = 1 -> miu:(s'= 3);

    // Alldown
    [Alldown] true -> (s'= 0); 
endmodule
//-------------------------------------------------------


// The system is operational
formula up = ((n2!= 6 & n1!= 3 & n0!= 1) & (s = 3|s = 2));
// The system temporarily fails and can still be reset through the scrubbing strategy
formula repair_down = (n2!= 6 & n1!= 3 & n0!= 1) & (s = 1);
// Due to the occurrence of run shock or extreme shock, the system permanently fails
formula down = (n2 = 6|n1 = 3|n0 = 1) & (s = 0); 

label "down" = (n2 = 6|n1 = 3|n0 = 1) & (s = 0); 
label "repair_down" = (n2!= 6 & n1!= 3 & n0!= 1)& (s = 1);
label "up" = (n2!= 6 & n1!= 3 & n0!= 1)& (s = 3|s = 2);

// the system is operational
rewards "up"
    up: 1;
    repair_down:0;
    down:0;
endrewards



