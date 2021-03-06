function varargout = Draw_Spine_Curve(varargin)
% DRAW_SPINE_CURVE MATLAB code for Draw_Spine_Curve.fig
%      DRAW_SPINE_CURVE, by itself, creates a new DRAW_SPINE_CURVE or raises the existing
%      singleton*.
%
%      H = DRAW_SPINE_CURVE returns the handle to a new DRAW_SPINE_CURVE or the handle to
%      the existing singleton*.
%
%      DRAW_SPINE_CURVE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DRAW_SPINE_CURVE.M with the given input arguments.
%
%      DRAW_SPINE_CURVE('Property','Value',...) creates a new DRAW_SPINE_CURVE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Draw_Spine_Curve_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Draw_Spine_Curve_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Draw_Spine_Curve

% Last Modified by GUIDE v2.5 19-Jan-2018 10:55:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Draw_Spine_Curve_OpeningFcn, ...
    'gui_OutputFcn',  @Draw_Spine_Curve_OutputFcn, ...
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


% --- Executes just before Draw_Spine_Curve is made visible.
function Draw_Spine_Curve_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Draw_Spine_Curve (see VARARGIN)

% Choose default command line output for Draw_Spine_Curve
handles.output = hObject;
handles.ctrl_key = 0;

%%%%% configs
handles.scatter_size = 5;
handles.scatter_type = 'b--o';
handles.plot_type='LineWidth';
handles.plot_size = 2.5;
handles.color = [1,0,0;0,0,1;0,1,0];
handles.showPID = 1;
handles.save_dir = '';

if ~isfield(handles,'root_dir')
    handles.root_dir = 'D:\Project\spine_seg_spline\temp\test_dcm_531\*.dcm';
    %'C:\Users\qinsh\OneDrive\Project\Graduation2017\journal\test_images/*.dcm');
end

%%%% open dicom image
labelTop=['<HTML><center><h3>Load EOS</h3> </HTML>'];
set(handles.open_Btn, 'string',labelTop );


%%%% adjust new curve
labelTop=['<HTML> <table frame="border"><tr><center><h3> ADJUST </h3> <tr></table></HTML>'];
set(handles.adjust_Btn, 'string',labelTop );


%%%% fill display
imshow(ones(2000,1000),[],'Parent',handles.axes1);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Draw_Spine_Curve wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Draw_Spine_Curve_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in open_Btn.
function open_Btn_Callback(hObject, eventdata, handles)
% hObject    handle to open_Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

[filename, pathname] = uigetfile(handles.root_dir,'File Selector');
file = fullfile(pathname,filename);
if filename == 0
    return;
end

set(handles.ang1_upper,'String','');
set(handles.ang1_apex,'String','');
set(handles.ang1_lower,'String','');
set(handles.ang2_upper,'String','');
set(handles.ang2_apex,'String','');
set(handles.ang2_lower,'String','');


handles.FileName = file;
handles.Ori_Image = dicomread(file);
%handles.Resize_Image = imresize(handles.Ori_Image,0.5);
handles.Resize_Image = handles.Ori_Image;
imshow(handles.Resize_Image,[],'Parent',handles.axes1); hold(handles.axes1,'on');
handles.Adj = 1;

info = dicominfo(file);

if(length(info.PatientID)<2)
    [~,idx,~] = fileparts(handles.FileName);
    handles.pid = idx;
else
    handles.pid = info.PatientID;
end

if handles.showPID == 0
    handles.pid(3:end)='*';
end
set(handles.id_txt,'string',handles.pid);


%------ fit
if handles.Adj == 1
    [handles.Curve,handles.Bin_Image] = GrayScaleBased('process',handles.Ori_Image);
    handles.last_Bin_Image = handles.Bin_Image;
    handles.Adj = 2;
else
    pos = ginput(1);
    [handles.Curve,handles.Bin_Image] = GrayScaleBased('update',handles.Bin_Image,pos);
    handles.last_Bin_Image = handles.Bin_Image;
end

%---------
if ~isfield(handles,'Curve')
    msgbox('No spine line generated !');
    return;
end
% clear display in the first
cla(handles.axes1,'reset');
% show image and curve
update_curve_disp(handles);
guidata(hObject, handles);



% -- sub function to update curve
function update_curve_disp(handles)
%cla handles.axes1 reset;
imshow(handles.Resize_Image,[],'Parent',handles.axes1); hold(handles.axes1,'on');
%scatter(handles.Curve(2,:),handles.Curve(1,:),'Parent',handles.axes1,3,handles.color(3,:),'filled-o'); hold(handles.axes1,'on');

vv = handles.Curve';
[handles.Couple,handles.Angle,pen_line] = find_cobbs(vv);
update_cobb_text(handles);

%%% reserved for other visual model
% for i= 1:4:size(pen_line,1)
%     color_id = (i-1)/4+1;
%     plot(pen_line(i,:),pen_line(i+1,:),'LineWidth',handles.plot_size,'Color',handles.color(color_id,:),'Parent',handles.axes1);hold(handles.axes1,'on');
%     plot(pen_line(i+2,:),pen_line(i+3,:),'LineWidth',handles.plot_size,'Color',handles.color(color_id,:),'Parent',handles.axes1);hold(handles.axes1,'on');
% end
handles.lls = cell(numel(handles.Angle)*2,1);
for i= 1:numel(handles.Angle)
    handles.lls{2*i-1} = imline(handles.axes1,pen_line(4*i-3,:),pen_line(4*i-2,:));
    setColor(handles.lls{2*i-1},handles.color(i,:));
    handles.lls{2*i} = imline(handles.axes1,pen_line(4*i-1,:)-30,pen_line(4*i,:)-30);
    setColor(handles.lls{2*i},handles.color(i,:));
end
for i = 1:numel(handles.lls)
    addNewPositionCallback(handles.lls{i},@(pos) line_segments(handles));
end

%-- callback function: moving line segments
function line_segments(handles)
angles = zeros(numel(handles.lls),1);
for i=1:numel(handles.lls)
    pos =  handles.lls{i}.getPosition();
    pos = pos(2,:)-pos(1,:);
    angles(i) = atan(pos(2)/pos(1));
end
for i=1:numel(angles)/2
    handles.Angle(i) = rad2deg(angles(2*i-1) - angles(2*i));
end
update_cobb_text(handles);


% -- sub function: update Cobb angle txt edit
function update_cobb_text(handles)
% update text edit (Cobb angle)
for i=1:3
    set(eval(strcat('handles.cobb_Edit',num2str(i))),'String',' ');
end
for i=1:numel(handles.Angle)
    ang = num2str(handles.Angle(i));
    set(eval(strcat('handles.cobb_Edit',num2str(i))),'String',ang);
end




% --- Executes on button press in adjust_Btn.
function adjust_Btn_Callback(hObject, eventdata, handles)
% hObject    handle to adjust_Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

if ~isfield(handles,'Ori_Image')
    msgbox('Please load an image in the first !');
    return;
end

if handles.Adj == 1
    [handles.Curve,handles.Bin_Image] = GrayScaleBased('process',handles.Ori_Image);
    handles.last_Bin_Image = handles.Bin_Image;
    handles.Adj = 2;
else
    [posx,posy,but] = ginput(1);%,handles.axes1);
    if(but==27 || but==13)
    else
        pos=[posx,posy]/2;
        if length(pos)>1
            handles.last_Bin_Image = handles.Bin_Image;
            [handles.Curve,handles.Bin_Image] = GrayScaleBased('update',handles.Bin_Image,pos);
        end
    end
end
update_curve_disp(handles);
guidata(hObject, handles);


function cobb_Edit1_Callback(~, ~, ~)
% hObject    handle to cobb_Edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cobb_Edit1 as text
%        str2double(get(hObject,'String')) returns contents of cobb_Edit1 as a double


% --- Executes during object creation, after setting all properties.
function cobb_Edit1_CreateFcn(hObject, ~, ~)
% hObject    handle to cobb_Edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --------------------------------------------------------------------
function save_Opt_Callback(hObject, ~, handles)
% hObject    handle to save_Opt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function cobb_Edit2_Callback(~, ~, ~)
% hObject    handle to cobb_Edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cobb_Edit2 as text
%        str2double(get(hObject,'String')) returns contents of cobb_Edit2 as a double


% --- Executes during object creation, after setting all properties.
function cobb_Edit2_CreateFcn(hObject, ~, ~)
% hObject    handle to cobb_Edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ang1_upper_Callback(hObject, eventdata, handles)
% hObject    handle to ang1_upper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang1_upper as text
%        str2double(get(hObject,'String')) returns contents of ang1_upper as a double


% --- Executes during object creation, after setting all properties.
function ang1_upper_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang1_upper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ang1_lower_Callback(hObject, eventdata, handles)
% hObject    handle to ang1_lower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang1_lower as text
%        str2double(get(hObject,'String')) returns contents of ang1_lower as a double


% --- Executes during object creation, after setting all properties.
function ang1_lower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang1_lower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ang2_upper_Callback(hObject, eventdata, handles)
% hObject    handle to ang2_upper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang2_upper as text
%        str2double(get(hObject,'String')) returns contents of ang2_upper as a double


% --- Executes during object creation, after setting all properties.
function ang2_upper_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang2_upper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ang2_lower_Callback(hObject, eventdata, handles)
% hObject    handle to ang2_lower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang2_lower as text
%        str2double(get(hObject,'String')) returns contents of ang2_lower as a double


% --- Executes during object creation, after setting all properties.
function ang2_lower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang2_lower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Copyright_Callback(hObject, eventdata, handles)
% hObject    handle to Copyright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({'Copyright:';'CUHK: Dept.Ort'});




% --------------------------------------------------------------------
function Options_Callback(hObject, eventdata, handles)
% hObject    handle to Options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function set_dcm_base_dir_Callback(hObject, eventdata, handles)
% hObject    handle to set_dcm_base_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
tmp_dir = uigetdir();
if(tmp_dir==0)
    return;
end
if(isdir(tmp_dir))
    handles.root_dir = fullfile(tmp_dir,'*.dcm');
end
guidata(hObject, handles);



% --------------------------------------------------------------------
function hid_id_Callback(hObject, eventdata, handles)
% hObject    handle to hid_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
if handles.showPID==1
    handles.showPID=0;
    set(handles.hid_id,'Label','Show ID');
else
    handles.showPID=1;
    set(handles.hid_id,'Label','Hide ID');
end %end if

guidata(hObject, handles);





function ang1_apex_Callback(hObject, eventdata, handles)
% hObject    handle to ang1_apex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang1_apex as text
%        str2double(get(hObject,'String')) returns contents of ang1_apex as a double


% --- Executes during object creation, after setting all properties.
function ang1_apex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang1_apex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ang2_apex_Callback(hObject, eventdata, handles)
% hObject    handle to ang2_apex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ang2_apex as text
%        str2double(get(hObject,'String')) returns contents of ang2_apex as a double


% --- Executes during object creation, after setting all properties.
function ang2_apex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ang2_apex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, eventdata, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

try
    fname = fullfile(handles.save_dir,[handles.pid,'.txt']);
    fileID = fopen(fname,'w');
    for ii=1:3
        Angle = str2double(get(eval(strcat('handles.cobb_Edit',num2str(ii))),'String'));
        if isnan(Angle)
            continue;
        end
        if Angle>0
            direct = 'R';
        else
            direct = 'L ';
        end
        str = sprintf('%d: %6s : %3f',ii,direct,abs(Angle));
        text(0,ii*120-60,str,'Color','red','FontSize',14);
        
        % write to log file
        fprintf(fileID,'%6s, %3f,',direct,abs(Angle));
    end
    save_single_fig_Callback(hObject, eventdata, handles)
catch
    % no ops
end

try
    fclose(fileID);
catch
    % no op
end % end try

guidata(hObject, handles);

% --------------------------------------------------------------------
function save_single_fig_Callback(hObject, eventdata, handles)
% hObject    handle to save_single_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
dirr = handles.save_dir;
if dirr == 0
    return;
end
filename = fullfile(dirr,[handles.pid,'.jpg']);
F = getframe(handles.axes1);
Image = frame2im(F);
imwrite(Image, filename);

guidata(hObject, handles);




% --------------------------------------------------------------------
function set_single_save_dir_Callback(hObject, eventdata, handles)
% hObject    handle to set_single_save_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
tmp_dir = uigetdir();
if(isdir(tmp_dir))
    handles.save_dir = tmp_dir;
end
guidata(hObject, handles);




% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
key = eventdata.Key;

switch key
    case 'control' % skip operation
    case 'a'
        adjust_Btn_Callback(hObject, eventdata, handles);
        
    case 'z' % step back one step
        if(handles.ctrl_key==1)
            if ~isfield(handles,'Ori_Image')
                msgbox('Please load an image in the first !');
                return;
            end
            pos=[-1,-1];
            handles.Bin_Image = handles.last_Bin_Image;
            [handles.Curve,handles.Bin_Image] = GrayScaleBased('update',handles.Bin_Image,pos);
            update_curve_disp(hObject, eventdata, handles);
        end % end if
        
    case 's'
        dirr = handles.save_dir;
        if dirr == 0
            return;
        end
        filename = fullfile(dirr,[handles.pid,'.jpg']);
        F = getframe(handles.axes1);
        Image = frame2im(F);
        imwrite(Image, filename);
        save_btn_Callback(hObject, eventdata, handles);
    otherwise
        % no op
end % end switch key

guidata(hObject, handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
key = eventdata.Key;
if(strcmp(key,'control'))
    handles.ctrl_key = 1;
end
guidata(hObject, handles);



% --- Executes on key release with focus on figure1 and none of its controls.
function figure1_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
key = eventdata.Key;
if(strcmp(key,'control'))
    handles.ctrl_key = 0;
end
guidata(hObject, handles);


%-----------------------------------------------------------
function cobb_Edit3_Callback(hObject, eventdata, handles)
% hObject    handle to cobb_Edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cobb_Edit3 as text
%        str2double(get(hObject,'String')) returns contents of cobb_Edit3 as a double


% --- Executes during object creation, after setting all properties.
function cobb_Edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cobb_Edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

 
% --------------------------------------------------------------------
function set_batch_res_save_dir_Callback(hObject, ~, handles)
% hObject    handle to set_batch_res_save_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;
uiwait(msgbox('Please select a folder to store results !','modal'));
dst_dir = uigetdir('Dir Selector');
if(dst_dir == 0)
    msgbox('invalid dir!');
    return
end
dcms = dir(handles.root_dir);
list = {};
for i = 1:length(dcms)
    [base_dir,~,~] = fileparts(handles.root_dir);
    list = [list,fullfile(base_dir,dcms(i).name)];
end
bundle_process(list,dst_dir);
guidata(hObject, handles);



