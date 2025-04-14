function error = objectiveFunction(x, epsilon_r, N, target_C)
    W = x(1);
    S = x(2);
    l = x(3);
    
    C_series = calculate_C_series(W, S, l, epsilon_r, N);
    error = abs(C_series - target_C);
end
