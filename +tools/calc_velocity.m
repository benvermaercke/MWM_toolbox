function velocity=calc_velocity(track_data)

time_step=min(diff(track_data(:,1)));

M=[track_data(1:end-1,2) track_data(2:end,2) track_data(1:end-1,3) track_data(2:end,3)];

diff_X=diff(M(:,1:2),[],2);
diff_Y=diff(M(:,3:4),[],2);
distance_vector=sqrt(diff_X.^2 + diff_Y.^2);

velocity=distance_vector/time_step;

