function analyze_plant(schedule)
global CYCLE_LENGTH;
global SIMULATION_HORIZON_IN_CYCLES;
global NUM_UNITS

fprintf('--- Stats for Plant --- \n')

for unit_num =1:NUM_UNITS
    
    utilization=zeros(SIMULATION_HORIZON_IN_CYCLES,1);
    for cycle_num=2:SIMULATION_HORIZON_IN_CYCLES - 1
        all_tasks=schedule{cycle_num}{unit_num};
        if length(all_tasks)>0
            last_task=all_tasks(end);
            utilization(cycle_num)= (last_task.end_time - CYCLE_LENGTH * (cycle_num - 1))*100 / CYCLE_LENGTH;
        else
            utilization(cycle_num)= 0;
        end
    end
    fprintf('Av. unit %d utilization: %f\n', unit_num, mean(utilization));
    %figure;bar(utilization);title('% utilization');
end; %for unit_num
