clear all

%% Reset Random number streams
s = RandStream('mt19937ar','Seed',0)
RandStream.setGlobalStream(s);

% % % % Load Random number Stream
% % globalStream = RandStream.getGlobalStream;
% % % load('RandomStreamState') % Uncomment to reload
% % % globalStream.State = myStreamState; % Uncomment to reload
% %
% % % Save Random number stream
% % myStreamState=globalStream.State; % Comment to reload
% % save('RandomStreamState') % Comment to reload

%% Define Constants and filenames
global SIMULINK_FILENAME;
global SAMPLING_INTERVAL;
global INITIAL_SETTLING_TIME;
global MIN_ORDER_SIZE;
global MAX_ORDER_SIZE;
global SIMULATION_HORIZON_IN_DAYS;
global CYCLE_LENGTH;
global SIMULATION_HORIZON_IN_CYCLES;
global PRODUCT_IDS;
global NUM_PRODUCTS;
global SET_POINTS;
global MAX_QUALITY;
global MIN_QUALITY;
global MAX_THROUGHPUTS;

%% Case study details
% Nominal setpoints [0 0.4 0 8.5 0.3 6]
SIMULINK_FILENAME = 'mpc_tmp';%%'error1234';
load mpc_tmpdata; % Need this to load the MPC controller and data

MIN_ORDER_SIZE = 6; %nominal value is 6 ;
MAX_ORDER_SIZE = 15;
PRODUCT_IDS=[1 2 3];
NUM_PRODUCTS = length(PRODUCT_IDS);
SET_POINTS= [0.30 0.34 0.38];
MIN_QUALITY =[0.28 0.33 0.36];
MAX_QUALITY =[0.32 0.36 0.39];
MAX_THROUGHPUTS=[30 31 29];%[25 25 25];
safetystock = [0 0 0];
INITIAL_SETTLING_TIME=1;

%% Simulation parameters
SAMPLING_INTERVAL = 10;
CYCLE_LENGTH=700;
SIMULATION_HORIZON_IN_CYCLES = 26; %Change with CYCLE_LENGTH
SIMULATION_HORIZON_IN_DAYS = SIMULATION_HORIZON_IN_CYCLES * CYCLE_LENGTH;

%% Initialize

inventory=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
demand=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
target_quantity=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
production=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
fulfilled=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
backlog=zeros(SIMULATION_HORIZON_IN_CYCLES,NUM_PRODUCTS);
schedule{SIMULATION_HORIZON_IN_CYCLES}=[];
y_time=SAMPLING_INTERVAL:SAMPLING_INTERVAL:SIMULATION_HORIZON_IN_DAYS;
y_quality=zeros(SIMULATION_HORIZON_IN_DAYS/ SAMPLING_INTERVAL);
y_throughput=zeros(SIMULATION_HORIZON_IN_DAYS/ SAMPLING_INTERVAL);
y_product_id=zeros(SIMULATION_HORIZON_IN_DAYS/ SAMPLING_INTERVAL);

last_setpoint=zeros(1,1);

%% Generate orders
orders=generate_orders();

%% SIMULATION LOOP BEGINS HERE %%
fprintf('Loading simulink model %s ...', SIMULINK_FILENAME);
load_system(SIMULINK_FILENAME);
fprintf(' Done\n');
for cycle_num = 2: SIMULATION_HORIZON_IN_CYCLES - 1
    
    disp(['Starting simulation for week ' num2str(cycle_num)]);
    %% Generate Schedule for Week w
    demand(cycle_num,:) = calculate_demand(orders,cycle_num);
    target_quantity(cycle_num,:) = demand(cycle_num,:)- inventory (cycle_num - 1,:) + backlog(cycle_num - 1,:) + safetystock;
    schedule{cycle_num}=schedule_generator(target_quantity(cycle_num,:),cycle_num);
    
    %% Simulate Schedule
    task=schedule{cycle_num};
    for subtask_num = 1:length(task)
        
        fprintf('Executing task %d for cycle %d producing product %d\n', subtask_num, cycle_num, task{subtask_num}.product_id)
        x_initial_product_setpoint=last_setpoint;
        x_new_product_setpoint=task{subtask_num}.set_point;
        x_throughput_setpoint=task{subtask_num}.speed;
        x_product_id=task{subtask_num}.product_id;
        
        StartTime=task{subtask_num}.start_time;
        StopTime=task{subtask_num}.end_time;
        simOut = sim(SIMULINK_FILENAME,'SrcWorkspace', 'current','StartTime',...
            num2str(StartTime - INITIAL_SETTLING_TIME),'StopTime',num2str(StopTime));
        last_setpoint = x_new_product_setpoint;
        
        %% Extract Simulation Data for task
        StartTime_index=round(StartTime/SAMPLING_INTERVAL);
        StopTime_index=round(StopTime/SAMPLING_INTERVAL);
        index_range=StopTime_index - StartTime_index;
        y_time(StartTime_index:StopTime_index)=simOut.get('y_quality').Time(end - index_range:end);
        y_quality(StartTime_index:StopTime_index)=simOut.get('y_quality').Data(end - index_range:end);
        y_throughput(StartTime_index:StopTime_index)=simOut.get('y_throughput').Data(end - index_range:end);
        y_product_id(StartTime_index:StopTime_index)=simOut.get('y_product_id').Data(end - index_range:end);
    end; %% for task_num
    
    %% Collect production statistics for that cycle
    
    cycle_StartTime_index=CYCLE_LENGTH*(cycle_num - 1)/SAMPLING_INTERVAL+1;
    cycle_StopTime_index=CYCLE_LENGTH*cycle_num/SAMPLING_INTERVAL;
    for prod_num=1:NUM_PRODUCTS
        t_index=find(y_product_id(cycle_StartTime_index:cycle_StopTime_index)==PRODUCT_IDS(prod_num));
        tq_index=find((y_quality(t_index+cycle_StartTime_index)>MIN_QUALITY(prod_num))& ...
            (y_quality(t_index+cycle_StartTime_index)<MAX_QUALITY(prod_num)));
        production(cycle_num,prod_num) =production(cycle_num,prod_num)+ sum(y_throughput(t_index(tq_index)+cycle_StartTime_index))*SAMPLING_INTERVAL;
        inventory(cycle_num,prod_num) = inventory(cycle_num -1 ,prod_num) + production(cycle_num,prod_num);
    end; %% for prod_num
    %% Fulfill orders
    order_due_dates=[orders(:).due_date];
    orders_fulfilled=[orders(:).fulfilled];
    selected_orders=find((order_due_dates<=(cycle_num+1)*CYCLE_LENGTH)& (orders_fulfilled==0));
    for id=selected_orders
        order=orders(id);
        neworder=order;
        neworder.delivery_date=CYCLE_LENGTH*(cycle_num);
        neworder.delivery_quantity=min(inventory(cycle_num,order.product_id),order.quantity);
        neworder.fulfilled = 1;
        inventory(cycle_num,order.product_id) = inventory(cycle_num,order.product_id) - neworder.delivery_quantity;
        fulfilled(cycle_num,order.product_id)=fulfilled(cycle_num,order.product_id)+neworder.delivery_quantity;
        orders(id)=neworder;
    end; %% for id
    
end; % for cycle_num

%% Analyze results
analyze_orders(orders,inventory);
analyze_plant(schedule);