function [orders] = generate_orders()

global MAX_ORDER_SIZE;
global MIN_ORDER_SIZE;
global SIMULATION_HORIZON_IN_DAYS;
global CYCLE_LENGTH;
global NUM_PRODUCTS;


quantities=round((MAX_ORDER_SIZE-MIN_ORDER_SIZE)*rand(SIMULATION_HORIZON_IN_DAYS*NUM_PRODUCTS,1)+MIN_ORDER_SIZE);
types=randi(NUM_PRODUCTS+1,SIMULATION_HORIZON_IN_DAYS*NUM_PRODUCTS,1)-1;
due_dates=randi(SIMULATION_HORIZON_IN_DAYS - 2*CYCLE_LENGTH,SIMULATION_HORIZON_IN_DAYS*NUM_PRODUCTS,1)+ 2*CYCLE_LENGTH;

[sorted_due_dates, idx]=sort(due_dates);
sorted_quantities = quantities(idx);
sorted_types=types(idx);

num_order=1;
for i=1:SIMULATION_HORIZON_IN_DAYS*NUM_PRODUCTS
    if sorted_types(i)>0
        orders(num_order).product_id = sorted_types(i);
        orders(num_order).quantity = sorted_quantities(i);
        orders(num_order).due_date = sorted_due_dates(i);
        orders(num_order).delivery_date = [];
        orders(num_order).delivery_quantity = [];
        orders(num_order).fulfilled = 0; 
        num_order=num_order+1;
    end; %%if
end; %% for
