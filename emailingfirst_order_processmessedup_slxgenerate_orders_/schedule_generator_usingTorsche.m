function [sorted_jobs]=schedule_generator_usingTorsche(target_quantity,cycle_num)

global NUM_PRODUCTS;
global PRODUCT_IDS;
global SET_POINTS;
global MAX_THROUGHPUTS;
global SAMPLING_INTERVAL;
global CYCLE_LENGTH;


if sum(target_quantity)<=0
    exit;
end;

jobs=struct('set_point',[],'product_id',[],'quantity_demand',[],'speed',[],'start_time',[],'end_time',[]);
cycle_start_time = (cycle_num - 1)*CYCLE_LENGTH ;
cycle_end_time = cycle_num *CYCLE_LENGTH;

%% Provide Data to Torsche


for task_num=1:NUM_PRODUCTS
    duration = target_quantity(task_num)/MAX_THROUGHPUTS(task_num);
    duration = round(duration/SAMPLING_INTERVAL)*SAMPLING_INTERVAL;
    list_of_tasks{task_num} = task(['task' num2str(task_num)], duration,cycle_start_time,inf,cycle_end_time);
end

%% Run Torsche
my_tasks=taskset(list_of_tasks);
problem_type = problem('P|prec|Cmax');
num_of_processors = 1;
scheduling_strategy = 'LPT'; % Can take values 'EST', 'ECT', 'LPT', 'SPT' or any handler of function,
optimal_schedule= listsch(my_tasks,problem_type,num_of_processors,scheduling_strategy);


%%Extract results and export
task_num=1;
for prod_num=1:NUM_PRODUCTS
    start_time=get_scht(optimal_schedule.tasks(prod_num))+ SAMPLING_INTERVAL;
    
    if start_time < cycle_end_time
        jobs(task_num).set_point=SET_POINTS(task_num);
        jobs(task_num).product_id=PRODUCT_IDS(task_num);
        jobs(task_num).quantity_demand=target_quantity(task_num);
        jobs(task_num).speed=MAX_THROUGHPUTS(task_num);
        jobs(task_num).start_time=start_time;
        jobs(task_num).end_time=min(cycle_end_time ,...
            start_time+get(optimal_schedule.tasks(task_num),'ProcTime'));
        task_num=task_num+1;
    end; % if
end; %% for task_num

[y,i]=sort([jobs(:).start_time]);
sorted_jobs=jobs(i);
