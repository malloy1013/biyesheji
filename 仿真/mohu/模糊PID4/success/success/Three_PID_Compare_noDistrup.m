function varargout = Three_PID_Compare_noDistrup(varargin)
% THREE_PID_COMPARE_NODISTRUP M-file for Three_PID_Compare_noDistrup.fig
%      THREE_PID_COMPARE_NODISTRUP, by itself, creates a new THREE_PID_COMPARE_NODISTRUP or raises the existing
%      singleton*.
%
%      H = THREE_PID_COMPARE_NODISTRUP returns the handle to a new THREE_PID_COMPARE_NODISTRUP or the handle to
%      the existing singleton*.
%
%      THREE_PID_COMPARE_NODISTRUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THREE_PID_COMPARE_NODISTRUP.M with the given input arguments.
%
%      THREE_PID_COMPARE_NODISTRUP('Property','Value',...) creates a new THREE_PID_COMPARE_NODISTRUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Three_PID_Compare_noDistrup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Three_PID_Compare_noDistrup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Three_PID_Compare_noDistrup

% Last Modified by GUIDE v2.5 30-May-2010 09:46:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Three_PID_Compare_noDistrup_OpeningFcn, ...
                   'gui_OutputFcn',  @Three_PID_Compare_noDistrup_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Three_PID_Compare_noDistrup is made visible.
function Three_PID_Compare_noDistrup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Three_PID_Compare_noDistrup (see VARARGIN)

% Choose default command line output for Three_PID_Compare_noDistrup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Three_PID_Compare_noDistrup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Three_PID_Compare_noDistrup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%read PID parameters from GUI
Kp_gui=str2num(get(handles.edit4,'string'));
Ki_gui=str2num(get(handles.edit5,'string'));
Kd_gui=str2num(get(handles.edit6,'string'));

dKp_gui=str2num(get(handles.edit7,'string'));
dKi_gui=str2num(get(handles.edit8,'string'));
dKd_gui=str2num(get(handles.edit9,'string'));

nnKp=str2num(get(handles.edit10,'string'));
nnKi=str2num(get(handles.edit11,'string'));
nnKd=str2num(get(handles.edit12,'string'));

%read fis from file
fuzzyPID=readfis('fuzzyPID');

%transform GUI variable to WorkSpace
assignin('base','Kp_gui',Kp_gui);
assignin('base','Ki_gui',Ki_gui);
assignin('base','Kd_gui',Kd_gui);

assignin('base','dKp_gui',dKp_gui);
assignin('base','dKi_gui',dKi_gui);
assignin('base','dKd_gui',dKd_gui);

assignin('base','fuzzyPID',fuzzyPID);

%open PIDController.mdl
load_system('PIDController_1');

%set parameters of simulink mdl file
set_param('PIDController_1/PID','Kp','Kp_gui','Ki','Ki_gui','Kd','Kd_gui');
sim('PIDController_1.mdl',[],simset('DstWorkspace ','base')); 

%de/dt of PID control
ec_gui=evalin('base','ec');

%maximum abs(de/dt) of PID control
derror_max=0;
for ii=1:1001
    if derror_max<abs(ec_gui(ii))
        derror_max=abs(ec_gui(ii));        
    end
end

assignin('base','derror_max',derror_max);

%open Fuzzy_PID_1.mdl
load_system('Fuzzy_PID_1')

set_param('Fuzzy_PID_1/PID','Kp','Kp_gui','Ki','Ki_gui','Kd','Kd_gui');
set_param('Fuzzy_PID_1/FuzPID','Kp','Kp_gui','Ki','Ki_gui','Kd','Kd_gui','dKp','dKp_gui','dKi','dKi_gui','dKd','dKd_gui','Ke','1','Kec','1/derror_max');

%run Fuzzy_PID file
sim('Fuzzy_PID_1.mdl',[],simset('DstWorkspace ','base')); 

%plot input and outputs
axes(handles.axes1);

Uref_gui=evalin('base','Uref');
Ut1_gui=evalin('base','Ut1');
Ut2_gui=evalin('base','Ut2');
t_gui=evalin('base','t');


%%%%%%%%%%%%%%%%%RBF NN PID%%%%%%%%%%%%%%%%%%%%
ts=0.0001;%单个时间步长

Gp=tf([20000],[1,721/6,2020,1000/3]);%传递函数
Gpz=c2d(Gp,ts,'z');%离散化传递函数
[num,den]=tfdata(Gpz,'v');%取出z变换后传递函数的分子分母系数

h=zeros(6,1);%RBF函数

w=[-0.5359;0.1741;0.5042;0.7119;-0.0304;0.2666];

c=[10.8282    8.7916   11.9357    2.5122  -11.4472    5.4146;
   -1.3515    3.2425   -6.6360   -2.7096   -1.8995   -3.1160;
  -10.6009   -3.6080    3.6667   -8.5980   -7.6035    8.2084;];

b=[28.0810;8.4260;-38.7748;54.8844;-28.1179;50.9474];


w_1=w;w_2=w;w_3=w;%设定第k次，第k-1次和第k-2次权重初值

xite=0.40;%NNI网络的学习效率
alfa=0.05;%k-1次的惯性系数
belte=0.01;%k-2次的惯性系数

x=[0,0,0]';%NNI网络的输入量

c_1=c;c_2=c_1;c_3=c_2;
b_1=b;b_2=b_1;b_3=b_2;

xc=[0,0,0]';%NNC网络的输入量
xitec=0.60;%NNC网络的学习效率

%设定PID参数初值
wc=[nnKp,nnKd,nnKi];%NNC网络的输入权值
wc_1=wc;wc_2=wc;wc_3=wc;%初始化权值

error_1=0;error_2=0;%误差值初始化
y_1=0;y_2=0;y_3=0;%输出值初始化
u_1=0;u_2=0;u_3=0;%输入值初始化

ei=0;%ei用于存储误差累加值
c_size=size(c);%隐节点基带宽参数长度

for k=1:5000
    time(k)=k*ts;
    rin(k)=1;
    
    
    yrout(k)=1.0*rin(k);%yrout为参考模型的在输入下的输出

    %Linear model
    yout(k)=-den(2)*y_1-den(3)*y_2-den(4)*y_3+num(2)*u_1+num(3)*u_2+num(4)*u_3;%用差分方程求出输出
   
    for j=1:1:c_size(2)%6列
        h(j)=exp(-norm(x-c_1(:,j))^2/(2*b_1(j)*b_1(j)));%RBF函数为高斯函数
    end
        ymout(k)=w_1'*h;%网络辨识器的输出
    
    id=abs(yout(k)-ymout(k));%检测误差是否大于0.0001
    if id>0.0001,
    %-----------------Adjusting RBF parameters-----------------------%
        d_w=0*w;        % Defining matrix number of d_w equal to that of w
        for j=1:1:6
            d_w(j)=xite*(yout(k)-ymout(k))*h(j);
        end
        w=w_1+d_w+alfa*(w_1-w_2)+belte*(w_2-w_3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        d_b=0*b;
        for j=1:1:6
            d_b(j)=xite*(yout(k)-ymout(k))*w_1(j)*h(j)*(b_1(j)^-3)*norm(x-c_1(:,j))^2;
        end
        b=b_1+ d_b+alfa*(b_1-b_2)+belte*(b_2-b_3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for j=1:1:6
            for i=1:1:3
                d_c(i,j)=xite*(yout(k)-ymout(k))*w_1(j)*h(j)*(x(i)-c_1(i,j))*(b_1(j)^-2);
            end
        end
        c=c_1+d_c+alfa*(c_1-c_2)+belte*(c_2-c_3);
    end 
    %%%%%%%%%%% Calculating Jacobian %%%%%%%%%%%%
    dyu=0;
    for j=1:1:c_size(2)
        dyu=dyu+w(j)*h(j)*(-x(1)+c(1,j))/b(j)^2;
    end
    dyout(k)=dyu;
    %%%%%%Parameters Return%%%%%%%
    error(k)=yrout(k)-yout(k);
    xc(1)=error(k);
    xc(2)=(error(k)-error_1)/ts;
    ei=ei+error(k)*ts;%误差累加（理解为积分）
    xc(3)=ei;
    
    u(k)=wc*xc;  %Control law
    if u(k)>10,
        u(k)=10;
    end   
    if u(k)<-10,
        u(k)=-10;
    end   
  
    d_wc=0*wc;      % Defining matrix number of d_w equal to that of w
    for j=1:1:3
        d_wc(j)=xitec*error(k)*xc(j)*dyout(k);
    end
    wc=wc_1+d_wc+alfa*(wc_1-wc_2)+belte*(wc_2-wc_3);
    
    error_2=error_1;error_1=error(k);%误差值更新
    
    u_3=u_2;u_2=u_1;u_1=u(k);%输入值更新
    y_3=y_2;y_2=y_1;y_1=yout(k);%输出值更新
    
    x(3)=y_2;
    x(2)=y_1;
    x(1)=u_1;
    
    w_3=w_2;w_2=w_1;w_1=w;
    c_3=c_2;c_2=c_1;c_1=c;
    b_3=b_2;b_2=b_1;b_1=b;
    wc_3=wc_2;wc_2=wc_1;wc_1=wc;

end
%%%%%%%%%%%%%%%%%%%%%%RBF NN PID%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ut3_gui=zeros(5001,1);
Ut3_gui(2:5001)=yout;
plot(t_gui,Uref_gui,t_gui,Ut1_gui,t_gui,Ut2_gui,t_gui,Ut3_gui);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf)
run('zhujiemian')

function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double


% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1
