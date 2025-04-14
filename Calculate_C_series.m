function C_series = calculate_C_series(W, S, l, epsilon_r, N)
    a = W / 2;
    b = (W + S) / 2;
    
    k = tan(pi * a / (4 * b))^2;
    k_prime = sqrt(1 - k^2);
    
    if (k >= 0.707 && k <= 1)
        K_ratio = (1 / pi) * log(2 * (1 + sqrt(k)) / (1 - sqrt(k)));
    else
        K_ratio = pi / log(2 * (1 + sqrt(k_prime)) / (1 - sqrt(k_prime)));
    end
    
    C_series = (1e-3 * epsilon_r / (18 * pi)) * K_ratio * (N - 1) * l;
end
