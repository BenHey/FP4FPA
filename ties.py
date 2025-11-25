import numpy as np
from matplotlib import pyplot as plt


plt.style.use('seaborn-v0_8-darkgrid') 


fig, axes = plt.subplots(1, 3, figsize=(15, 4), dpi=100)


ties_list = ["loss", "win", "share"]

for q, ties in enumerate(ties_list):
    n_iter = 300
    h = 0.01
    G = lambda b: np.minimum(1/(1 - b + 1e-10) - 1, 1)  
    
    def get_init_history(bid_set): 
        history = np.zeros_like(bid_set)
        history[0] = 0.01
        return history
    
    def get_i_payoff(ties): 
        if ties == "loss": 
            return lambda my_bid, competition: (1 - my_bid) * (1 + (1 if my_bid > competition else 0)) * 0.5
        if ties == "win":
            return lambda my_bid, competition: (1 - my_bid) * (1 + (1 if my_bid >= competition else 0)) * 0.5
        if ties == "share":
            return lambda my_bid, competition: (1 - my_bid) * (1 + (1 if my_bid > competition else 0) + (0.5 if my_bid == competition else 0)) * 0.5
        assert False, f"Unknown ties parameter: {ties}"
    
    i_payoff = get_i_payoff(ties)
    bid_set = np.arange(0, 1 + h, h)
    history = get_init_history(bid_set)
    
    def payoff(bid, history):
        return np.sum([i_payoff(bid, b) * weight for b, weight in zip(bid_set, history)])
    
    for _ in range(n_iter):
        i_bid = np.argmax([payoff(bid, history) for bid in bid_set])
        history[i_bid] += 1
    

    ax = axes[q]
    history_cdf = np.cumsum(history / np.sum(history))
    

    ax.plot(bid_set, G(bid_set), label="Theory", linewidth=2.5, color='#2E86AB', alpha=0.8)
    ax.plot(bid_set, history_cdf, label="Fictitious Play", linewidth=2, 
            color='#E63946', linestyle='--', alpha=0.8)
    
    ax.set_title(f'Ties: {ties.capitalize()}', fontsize=13, fontweight='bold', pad=10)
    ax.set_xlabel('Bid', fontsize=11)
    ax.set_ylabel('Cumulative Distribution', fontsize=11)
    
   
    ax.grid(True, alpha=0.3, linestyle=':', linewidth=0.5)
    

    ax.legend(loc='best', framealpha=0.9, fontsize=10)
    
    
    ax.set_xlim([0, 1])
    ax.set_ylim([0, 1.05])
    
    
    ax.tick_params(labelsize=9)

plt.tight_layout()



plt.savefig("comparison.png")
plt.show()
