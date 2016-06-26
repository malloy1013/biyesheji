function varargout = sjwlPID_withDistrup(varargin)
% SJWLPID_WITHDISTRUP M-file for sjwlPID_withDistrup.fig
%      SJWLPID_WITHDISTRUP, by itself, creates a new SJWLPID_WITHDISTRUP or raises the existing
%      singleton*.
%
%      H = SJWLPID_WITHDISTRUP returns the handle to a new SJWLPID_WITHDISTRUP or the handle to
%      the existing singleton*.
%
%      SJWLPID_WITHDISTRUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SJWLPID_WITHDISTRUP.M with the given input arguments.
%
%      SJWLPID_WITHDISTRUP('Property','Value',...) creates a new SJWLPID_WITHDISTRUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sjwlPID_withDistrup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sjwlPID_withDistrup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sjwlPID_withDistrup

% Last Modified by GUIDE v2.5 30-May-2010 13:37:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sjwlPID_withDistrup_OpeningFcn, ...
                   'gui_OutputFcn',  @sjwlPID_withDistrup_OutputFcn, ...
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


% --- Executes just before sjwlPID_withDistrup is made visible.
function sjwlPID_withDistrup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sjwlPID_withDistrup (see VARARGIN)

% Choose default command line output for sjwlPID_withDistrup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes sjwlPID_withDistrup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = sjwlPID_withDistrup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nnKp=str2num(get(handles.edit1,'string'));
nnKi=str2num(get(handles.edit2,'string'));
nnKd=str2num(get(handles.edit3,'string'));
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
T=10000;
for k=1:T
    time(k)=k*ts;
    rin(k)=1;
    
    
    yrout(k)=1.0*rin(k);%yrout为参考模型的在输入下的输出

     if k>6000&&k<8000
       yrout(k)=1.0*rin(k)-0.1*sin((k-6000)/2000*pi);
     end
    
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
t=0:ts:ts*(T-1);
axes(handles.axes1);
plot(t,yrout,t,yout);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf)
run('zhujiemian')


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
