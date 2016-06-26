% S-Function --Sregulationc
function[sys,x0]=Sregulation(t,x,u,flag)
global Ke Kec Ku;
Ke=2;Kec=1;Ku=1;
if flag==0
    sys=[0,0,3,2,0,1];    
    x0=[];
    
elseif flag==3
     if abs(u(1))>1
         sys(1)=1*Ke*u(1);
         sys(2)=0.1*Kec*u(2);
         sys(3)=30*Ku;
     elseif abs(u(1))>0.2
         sys(1)=0.5*Ke*u(1);
         sys(2)=0.2*Kec*u(2);
         sys(3)=30*Ku;
     else 
         sys(1)=0.3*Ke*u(1);
         sys(2)=0.3*Kec*u(2);
         sys(3)=30*Ku;
          end
     else        sys=[];
end