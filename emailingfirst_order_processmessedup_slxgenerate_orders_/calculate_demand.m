function [demand]=calculate_demand(orders,cycle_num)
global CYCLE_LENGTH;
global NUM_PRODUCTS;

due_dates=[orders(:).due_date];
selected_id=find((due_dates>cycle_num*CYCLE_LENGTH)&(due_dates<=(cycle_num+1)*CYCLE_LENGTH));
%%types=[orders(:).type]; DELETE???

demand=zeros(NUM_PRODUCTS,1);
for id=[selected_id]
    order=orders(id);
    %%dt=order.due_date-cycle_num*CYCLE_LENGTH; DELETE???
    demand(order.product_id)=demand(order.product_id)+order.quantity;
end; %% for

end

