%����PWM�������źų���
%duyus 2004,1,21
function y=pwm_control(x)  % m����
	if x<=-2.5
        y=6;
     elseif x<=-1.5
             y=4;
      elseif x<=-0.8
             y=2;
        elseif x<=-0.1
             y=0.01;
         elseif x<=0.1
             y=0;
          elseif x<=0.8
             y=-0.01;
         elseif x<=1.5
             y=-2;
        elseif x<=2.5
             y=-4;
      else y=-6;
     end
 

