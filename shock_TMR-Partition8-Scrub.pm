ctmc

//-----------------------------------------------------------------
// TMR-Partition8-Scrub Mode

// Observatation Time
const int T;

const double shockrate1;// Rate of type I shock 
const double shockrate2;// Rate of type II shock
const double shockrate3;// Rate of type III shock

const double Rate1; // Failure rate of a module (s = 1)
const double Rate2; // Failure rate of a module(s = 2)
const double Rate3; // Failure rate of a module (s = 3)

const double rate1 = Rate1/8; // Failure rate of one modular of a specific partition (s = 1)
const double rate2 = Rate2/8;  // Failure rate of one modular of a specific partition (s = 2)
const double rate3 = Rate3/8;  // Failure rate of one modular of a specific partition (s = 3)

const double t;  // scrub interval
const double miu = 1/(3600*t); //scrub rate

const double p;//  partition factor


//The Mixed Extreme Run Degraded model (MERD-Shock model)
module CRshock
                       // ns is the cumulative number of continuous shocks when the system is at s-level        
    n2:[0..6] init 0;  // st = 2,l2 = 6  
    n1:[0..3] init 0;  // st = 1,l1 = 3
    n0:[0..2] init 0;  // st = 0,l0 = 1
    st:[0..2] init 2;  // The ability of the system to resist a continuous number of Type-II shocks

    // st = 2
    [] st = 2 & n2 < 5 -> shockrate2:(n2'= n2 + 1);// When a type II shock occurs and n2 < 5, state n2 transfer to n2 + 1
    [] st = 2 & n2 < 3 -> shockrate1:(n2'= 0);// When a type I shock occurs and n2 < 3, n2 will be reset 0
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
// Partition 1
module P1

    // p1 = 3: all the three modules of partition 1 are in good condition
    // p1 = 2: SCU has occurred
    // p1 = 1: MCU has occurred
    // p1 = 0: system enters the absorption state because of cumulative failure shock or extreme failure shock.
    p1:[0..3] init 3;

    // SCU or DCU occurs within partition
    [] p1 = 3 -> st = 2? 3*0.99*rate1: st = 1? 3*0.99* rate2:  3*0.99*rate3: (p1'= 2);
    [] p1 = 3 -> st = 2? 3*0.01*rate1: st = 1? 3*0.01*rate2: 3*0.01*rate3: (p1'= 1);
    // DCUs occurring in adjacent partitions
    [p1mcu1] p1 = 3 -> 3*3*p:(p1'= 2);
    [p1mcu2] p1 = 3 -> 3*2*p:(p1'= 2);
    //scrub
    [scrub] p1 = 3 -> miu:(p1'= 3);

    // SCU or DCU occurs within partition
    [] p1 = 2 -> st = 2? 2*0.99*rate1: st = 1? 2*0.99*rate2: 2*0.99*rate3: (p1'= 1);
    [] p1 = 2 -> st = 2? 0.01*rate1: st = 1? 0.01*rate2: 0.01*rate3: (p1'= 1);
    // DCUs occurring in adjacent partitions
    [p1mcu1] p1 = 2 -> 2*3*p:(p1'= 1);
    [p1mcu2] p1 = 2 -> 2*2*p:(p1'= 1);
    // Scrub
    [scrub] p1 = 2 -> miu:(p1'= 3);
    [scrub] p1 = 1 -> miu:(p1'= 3);

    // Alldown
    [Alldown] true -> (p1'= 0); 
endmodule

// Partition2
module P2

    p2:[0..3] init 3;

    [] p2 = 3 -> st = 2? 3*0.99*rate1: st = 1? 3*0.99* rate2:  3*0.99*rate3: (p2'= 2);
    [] p2 = 3 -> st = 2? 3*0.01*rate1: st = 1? 3*0.01*rate2: 3*0.01*rate3: (p2'= 1);

    [p1mcu1] p2 = 3 -> (p2'= 2);

    [scrub] p2 = 3 -> (p2'= 3);

    [] p2 = 2 -> st = 2? 2*0.99*rate1: st = 1? 2*0.99*rate2: 2*0.99*rate3: (p2'= 1);
    [] p2 = 2 -> st = 2? 0.01*rate1: st = 1? 0.01*rate2: 0.01*rate3: (p2'= 1);

    [p1mcu2] p2 = 2 -> (p2'= 1);

    [scrub] p2 = 2 -> (p2'= 3);
    [scrub] p2 = 1 -> (p2'= 3);

    [Alldown] true -> (p2'= 0); 
endmodule

//Partition3
module P3

    p3:[0..3] init 3;

    [] p3 = 3 -> st = 2? 3*0.99*rate1: st = 1? 3*0.99* rate2:  3*0.99*rate3: (p3'= 2);
    [] p3 = 3 -> st = 2? 3*0.01*rate1: st = 1? 3*0.01*rate2: 3*0.01*rate3: (p3'= 1);

    [p3mcu1] p3 = 3 -> 3*3*p:(p3'= 2);
    [p3mcu2] p3 = 3 -> 3*2*p:(p3'= 2);

    [scrub] p3 = 3 -> (p3'= 3);

    [] p3 = 2 -> st = 2? 2*0.99*rate1: st = 1? 2*0.99*rate2: 2*0.99*rate3: (p3'= 1);
    [] p3 = 2 -> st = 2? 0.01*rate1: st = 1? 0.01*rate2: 0.01*rate3: (p3'= 1);

    [p3mcu1] p3 = 2 -> 2*3*p:(p3'= 1);
    [p3mcu2] p3 = 2 -> 2*2*p:(p3'= 1);

    [scrub] p3 = 2 -> (p3'= 3);
    [scrub] p3 = 1 -> (p3'= 3);

    [Alldown] true -> (p3'= 0); 
endmodule

module P4 = P2 [p2 = p4, p1mcu1 = p3mcu1,p1mcu2 = p3mcu2]  endmodule
module P5 = P3 [p3 = p5, p3mcu1 = p5mcu1,p3mcu2 = p5mcu2]  endmodule
module P6 = P2 [p2 = p6, p1mcu1 = p5mcu1,p1mcu2 = p5mcu2]  endmodule
module P7 = P3 [p3 = p7, p3mcu1 = p7mcu1,p3mcu2 = p7mcu2]  endmodule
module P8 = P2 [p2 = p8, p1mcu1 = p7mcu1,p1mcu2 = p7mcu2]  endmodule
//------------------------------------------------------------------------

// The system is operational
formula up = ((n2 != 6 & n1!= 3 & n0!= 1)& (p1 = 3|p1 = 2)&(p2 = 3|p2 = 2) & (p3 = 3|p3 = 2)&(p4 = 3|p4 = 2)&(p5 = 3|p5 = 2)&(p6 = 3|p6 = 2) & (p7 = 3|p7 = 2)&(p8 = 3|p8 = 2));
// The system temporarily fails and can still be reset through the scrubbing strategy
formula repair_down = (n2!= 6 & n1!= 3 & n0!= 1)& ((p1 = 1)|(p2 = 1)|(p3 = 1)|(p4 = 1)|(p5 = 1)|(p6 = 1)|(p7 = 1)|(p8 = 1));
// Due to the occurrence of run shock or extreme shock, the system permanently fails
formula down = (n2 = 6|n1 = 3|n0 = 1) & (p1 = 0) & (p2 = 0)&(p3 = 0)&(p4 = 0)&(p5 =0)&(p6 = 0)&(p7 = 0)&(p8 = 0);

label "down" = (n2 = 6|n1 = 3|n0 = 1) & (p1 = 0) & (p2 = 0)&(p3 = 0)&(p4 = 0)&(p5 =0)&(p6 = 0)&(p7 = 0)&(p8 = 0); //冲击和设计模式均进入吸收态
label "repair_down" = (n2!= 6 & n1!= 3 & n0!= 1)& ((p1 = 1)|(p2 = 1)|(p3 = 1)|(p4 = 1)|(p5 = 1)|(p6 = 1)|(p7 = 1)|(p8 = 1));
label "up" =((n2 != 6 & n1!= 3 & n0!= 1)& (p1 = 3|p1 = 2)&(p2 = 3|p2 = 2) & (p3 = 3|p3 = 2)&(p4 = 3|p4 = 2)&(p5 = 3|p5 = 2)&(p6 = 3|p6 = 2) & (p7 = 3|p7 = 2)&(p8 = 3|p8 = 2));

// The system is operational
rewards "up"
    up: 1;
    repair_down:0;
    down:0;
endrewards