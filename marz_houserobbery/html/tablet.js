console.log('Underground Marketplace JavaScript Loaded');

// Global variables
let currentTab = 'buy';
let playerMoney = 0;
let buyItems = [];
let sellItems = [];
let playerInventory = {};
let currentItem = null;
let currentMode = 'buy';

// Item icons for both buy and sell
const itemIcons = {
    // Buy items (tech equipment)
    'hack_laptop': '💻',
    'lockpick': '🔧',
    'loot_bag': '🎒',
    'drill': '🔩',
    'crowbar': '⚒️',
    'hacking_device': '📱',
    'thermal_goggles': '🥽',
    'radio': '📻',
    'gps_tracker': '📍',
    
    // Sell items (stolen goods)
    'rolex': '⌚',
    'diamond_ring': '💍',
    'gold_chain': '🏆',
    'electronics': '📱',
    'jewelry': '💎',
    'art_piece': '🎨',
    'cash': '💵',
    'bonds': '📜',
    'default': '📦'
};

// Initialize the system
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
});

function initializeEventListeners() {
    // Close button
    document.getElementById('close-btn').addEventListener('click', closeTablet);
    
    // Tab navigation
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            switchTab(e.target.dataset.tab);
        });
    });
    
    // Search functionality
    document.getElementById('search-input').addEventListener('input', filterItems);
    
    // Filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            setActiveFilter(e.target.dataset.filter);
        });
    });
    
    // Sell all button
    document.getElementById('sell-all-btn').addEventListener('click', sellAllItems);
    
    // Refresh button
    document.getElementById('refresh-btn').addEventListener('click', refreshInventory);
    
    // Quantity input
    document.getElementById('quantity-input').addEventListener('input', updateTotal);
    
    // ESC key to close
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            if (!document.getElementById('purchase-modal').classList.contains('hidden')) {
                closeModal();
            } else {
                closeTablet();
            }
        }
    });
}

// Message handler from Lua
window.addEventListener('message', function(event) {
    console.log('Received message:', event.data);
    
    const data = event.data;
    
    switch(data.action) {
        case 'openTablet':
            openTablet(data.items, data.inventory);
            break;
        case 'openTechShop':
            openTechShop(data.items, data.playerMoney);
            break;
        case 'closeTablet':
        case 'closeTechShop':
            closeTablet();
            break;
        case 'updateInventory':
            updateInventory(data.inventory);
            break;
        case 'updateMoney':
            updateMoney(data.money);
            break;
        case 'purchaseSuccess':
        case 'techBuySuccess':
            handlePurchaseSuccess(data.item, data.amount, data.totalPrice);
            break;
        case 'purchaseError':
        case 'techBuyError':
            handlePurchaseError(data.message);
            break;
    }
});

function openTablet(items, inventory) {
    console.log('Opening tablet in sell mode');
    currentTab = 'sell';
    currentMode = 'sell';
    sellItems = items || [];
    playerInventory = inventory || {};
    
    updateDisplay();
    document.getElementById('tablet-container').classList.remove('hidden');
    switchTab('sell');
}

function openTechShop(items, money) {
    console.log('Opening tablet in buy mode');
    currentTab = 'buy';
    currentMode = 'buy';
    buyItems = items || [];
    playerMoney = money || 0;
    
    updateDisplay();
    document.getElementById('tablet-container').classList.remove('hidden');
    switchTab('buy');
}

function closeTablet() {
    console.log('Closing tablet');
    document.getElementById('tablet-container').classList.add('hidden');
    document.getElementById('purchase-modal').classList.add('hidden');
    
    // Notify Lua based on current mode
    const callback = currentMode === 'buy' ? 'closeTechShop' : 'closeTablet';
    fetch(`https://${getResourceName()}/${callback}`, {
        method: 'POST',
        body: JSON.stringify({})
    }).catch(err => console.log('Close callback failed:', err));
}

function switchTab(tab) {
    currentTab = tab;
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    
    // Show/hide action bar for sell mode
    const actionBar = document.getElementById('action-bar');
    actionBar.style.display = tab === 'sell' ? 'flex' : 'none';
    
    // Update search placeholder
    const searchInput = document.getElementById('search-input');
    searchInput.placeholder = tab === 'buy' ? 'Search equipment...' : 'Search stolen goods...';
    
    renderItems();
}

function updateDisplay() {
    // Update money
    document.getElementById('player-money').textContent = playerMoney.toLocaleString();
    
    // Update item counts and values
    updateStats();
}

function updateStats() {
    let itemCount = 0;
    let totalValue = 0;
    
    if (currentTab === 'buy') {
        itemCount = buyItems.length;
        totalValue = buyItems.reduce((sum, item) => sum + item.price, 0);
    } else {
        const availableItems = sellItems.filter(item => (playerInventory[item.item] || 0) > 0);
        itemCount = availableItems.length;
        totalValue = availableItems.reduce((sum, item) => {
            const quantity = playerInventory[item.item] || 0;
            return sum + (item.price * quantity);
        }, 0);
    }
    
    document.getElementById('available-count').textContent = itemCount;
    document.getElementById('total-value').textContent = totalValue.toLocaleString();
}

function renderItems() {
    const itemsGrid = document.getElementById('items-grid');
    const items = currentTab === 'buy' ? buyItems : sellItems;
    
    if (!items || items.length === 0) {
        itemsGrid.innerHTML = `
            <div class="loading-state">
                <i class="fas fa-exclamation-triangle"></i>
                <span>No ${currentTab === 'buy' ? 'equipment' : 'items'} available</span>
            </div>
        `;
        return;
    }
    
    const filteredItems = getFilteredItems();
    itemsGrid.innerHTML = '';
    
    filteredItems.forEach((item, index) => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'item';
        itemDiv.style.animationDelay = `${index * 0.05}s`;
        
        if (currentTab === 'buy') {
            renderBuyItem(itemDiv, item);
        } else {
            renderSellItem(itemDiv, item);
        }
        
        itemsGrid.appendChild(itemDiv);
    });
    
    updateStats();
}

function renderBuyItem(itemDiv, item) {
    const canAfford = playerMoney >= item.price;
    const icon = itemIcons[item.item] || itemIcons.default;
    
    itemDiv.innerHTML = `
        <div class="item-icon">${icon}</div>
        <div class="item-details">
            <div class="item-name">${item.label}</div>
            <div class="item-description">${item.description}</div>
            <div class="item-meta">Range: ${item.MinAmount}-${item.MaxAmount} units</div>
        </div>
        <div class="item-actions">
            <div class="item-price">$${item.price.toLocaleString()}</div>
            <button class="action-btn" ${!canAfford ? 'disabled' : ''} 
                    onclick="openPurchaseModal('${item.item}', 'buy')">
                ${canAfford ? 'Purchase' : 'Insufficient Funds'}
            </button>
        </div>
    `;
}

function renderSellItem(itemDiv, item) {
    const quantity = playerInventory[item.item] || 0;
    const hasItems = quantity > 0;
    const icon = itemIcons[item.item] || itemIcons.default;
    
    itemDiv.innerHTML = `
        <div class="item-icon">${icon}</div>
        <div class="item-details">
            <div class="item-name">${item.label}</div>
            <div class="item-description">$${item.price} per unit</div>
            <div class="item-meta">Total value: $${(item.price * quantity).toLocaleString()}</div>
        </div>
        <div class="item-actions">
            <div class="item-quantity">You have: ${quantity}</div>
            <button class="action-btn sell-btn" ${!hasItems ? 'disabled' : ''} 
                    onclick="openPurchaseModal('${item.item}', 'sell')">
                ${hasItems ? 'Sell Items' : 'No Items'}
            </button>
        </div>
    `;
}

function getFilteredItems() {
    const items = currentTab === 'buy' ? buyItems : sellItems;
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    const activeFilter = document.querySelector('.filter-btn.active').dataset.filter;
    
    let filtered = items.filter(item => {
        // Search filter
        const matchesSearch = item.label.toLowerCase().includes(searchTerm) ||
                            item.description.toLowerCase().includes(searchTerm);
        
        // Value filter
        let matchesFilter = true;
        if (activeFilter === 'high-value') {
            matchesFilter = item.price >= 1000;
        }
        
        // For sell mode, only show items player has
        if (currentTab === 'sell') {
            const hasItem = (playerInventory[item.item] || 0) > 0;
            return matchesSearch && matchesFilter && hasItem;
        }
        
        return matchesSearch && matchesFilter;
    });
    
    return filtered;
}

function setActiveFilter(filter) {
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.filter === filter);
    });
    renderItems();
}

function filterItems() {
    renderItems();
}

function openPurchaseModal(itemId, mode) {
    const items = mode === 'buy' ? buyItems : sellItems;
    const item = items.find(i => i.item === itemId);
    
    if (!item) return;
    
    currentItem = { ...item, mode };
    
    // Update modal content
    document.getElementById('modal-title').textContent = mode === 'buy' ? 'Purchase Equipment' : 'Sell Stolen Goods';
    document.getElementById('modal-icon').textContent = itemIcons[item.item] || itemIcons.default;
    document.getElementById('modal-item-name').textContent = item.label;
    document.getElementById('modal-item-description').textContent = item.description;
    
    // Set quantity limits
    const quantityInput = document.getElementById('quantity-input');
    const quantityInfo = document.getElementById('quantity-info');
    
    if (mode === 'buy') {
        quantityInput.max = item.MaxAmount;
        quantityInput.value = item.MinAmount;
        quantityInfo.textContent = `Range: ${item.MinAmount}-${item.MaxAmount}`;
        document.getElementById('confirm-action').innerHTML = '<i class="fas fa-shopping-cart"></i> Purchase';
    } else {
        const available = playerInventory[item.item] || 0;
        quantityInput.max = available;
        quantityInput.value = Math.min(1, available);
        quantityInfo.textContent = `Available: ${available}`;
        document.getElementById('confirm-action').innerHTML = '<i class="fas fa-handshake"></i> Sell';
    }
    
    updateTotal();
    document.getElementById('purchase-modal').classList.remove('hidden');
}

function closeModal() {
    document.getElementById('purchase-modal').classList.add('hidden');
    currentItem = null;
}

function increaseQuantity() {
    const input = document.getElementById('quantity-input');
    const max = parseInt(input.max) || 999;
    input.value = Math.min(parseInt(input.value) + 1, max);
    updateTotal();
}

function decreaseQuantity() {
    const input = document.getElementById('quantity-input');
    const min = currentItem?.mode === 'buy' ? (currentItem.MinAmount || 1) : 1;
    input.value = Math.max(parseInt(input.value) - 1, min);
    updateTotal();
}

function updateTotal() {
    if (!currentItem) return;
    
    const quantity = parseInt(document.getElementById('quantity-input').value) || 1;
    const total = currentItem.price * quantity;
    document.getElementById('modal-total').textContent = total.toLocaleString();
}

function confirmAction() {
    if (!currentItem) return;
    
    const quantity = parseInt(document.getElementById('quantity-input').value) || 1;
    const total = currentItem.price * quantity;
    
    if (currentItem.mode === 'buy') {
        // Purchase item
        if (playerMoney < total) {
            alert('Insufficient funds!');
            return;
        }
        
        fetch(`https://${getResourceName()}/buyTechItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                item: currentItem.item,
                price: currentItem.price,
                quantity: quantity,
                total: total
            })
        }).catch(err => console.log('Buy callback failed:', err));
        
    } else {
        // Sell item
        fetch(`https://${getResourceName()}/sellItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                item: currentItem.item,
                price: currentItem.price,
                quantity: quantity
            })
        }).catch(err => console.log('Sell callback failed:', err));
    }
    
    closeModal();
}

function sellAllItems() {
    fetch(`https://${getResourceName()}/sellAllItems`, {
        method: 'POST',
        body: JSON.stringify({})
    }).catch(err => console.log('Sell all callback failed:', err));
}

function refreshInventory() {
    // Request updated inventory
    renderItems();
}

function updateInventory(inventory) {
    playerInventory = inventory || {};
    renderItems();
}

function updateMoney(money) {
    playerMoney = money || 0;
    document.getElementById('player-money').textContent = playerMoney.toLocaleString();
    renderItems(); // Re-render to update affordability
}

function handlePurchaseSuccess(itemName, amount, totalPrice) {
    console.log(`Success: ${amount}x ${itemName} for $${totalPrice}`);
    
    // Update money
    if (currentMode === 'buy') {
        playerMoney -= totalPrice;
        updateMoney(playerMoney);
    }
    
    renderItems();
}

function handlePurchaseError(message) {
    console.log('Purchase error:', message);
    alert(message);
}

function getResourceName() {
    return window.location.hostname === 'nui-game-internal' ? 
           window.location.pathname.split('/')[1] : 
           'marz_houserobbery';
}

console.log('Underground Marketplace system initialized');