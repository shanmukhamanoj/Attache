function [task]=schedule_generator(target_quantity,cycle_num)

global NUM_PRODUCTS;
global PRODUCT_IDS;
global SET_POINTS;
global MAX_THROUGHPUTS;
global SAMPLING_INTERVAL;
global CYCLE_LENGTH;

task = {};
if sum(target_quantity)>0
    subtask=struct('set_point',[],'product_id',[],'quantity_demand',[],'speed',[],'start_time',[],'end_time',[]);
else
    exit;
end; %%if

remaining_target_quantity=target_quantity;

next_start_time=(cycle_num - 1)*CYCLE_LENGTH + SAMPLING_INTERVAL;
subtask_num=1;
for prod_num = randperm(NUM_PRODUCTS)
    
    if ((round(remaining_target_quantity(prod_num))> 0) && (next_start_time < cycle_num *CYCLE_LENGTH))
        
        subtask(subtask_num).set_point=SET_POINTS(prod_num);
        subtask(subtask_num).product_id=PRODUCT_IDS(prod_num);
        
        subtask(subtask_num).speed=MAX_THROUGHPUTS(prod_num);
        subtask(subtask_num).start_time=next_start_time;
        
        end_time = min(cycle_num * CYCLE_LENGTH,next_start_time +...
            (remaining_target_quantity(prod_num)/subtask(subtask_num).speed));
        subtask(subtask_num).end_time=round(end_time/SAMPLING_INTERVAL)*SAMPLING_INTERVAL;
        
        subtask(subtask_num).quantity_demand= (subtask(subtask_num).end_time - ...
            subtask(subtask_num).start_time)*subtask(subtask_num).speed;
        remaining_target_quantity(prod_num)= remaining_target_quantity(prod_num)- ...
            subtask(subtask_num).quantity_demand;
        next_start_time=subtask(subtask_num).end_time + SAMPLING_INTERVAL;
        task=[task subtask(subtask_num)];
        subtask_num=subtask_num+1;
    end; %% if
end %% for prod_num



