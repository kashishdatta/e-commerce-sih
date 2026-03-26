import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def get_mock_kpis():
    return {
        "revenue": 1250430,
        "cac": 45.50,
        "ltv": 120.25,
        "churn_rate": 0.124
    }

def get_mock_rfm_data():
    np.random.seed(42)
    n_users = 1000
    
    data = {
        "anonymous_id": [f"user_{i}" for i in range(n_users)],
        "r_score": np.random.randint(1, 6, n_users),
        "f_score": np.random.randint(1, 6, n_users),
        "m_score": np.random.randint(1, 6, n_users),
        "lifetime_purchases": np.random.randint(1, 50, n_users),
        "lifetime_revenue": np.random.uniform(50, 5000, n_users),
        "recency_days": np.random.randint(1, 365, n_users),
        "avg_days_between_purchases": np.random.uniform(10, 90, n_users),
        "stddev_days_between_purchases": np.random.uniform(2, 20, n_users),
    }
    
    df = pd.DataFrame(data)
    
    # Calculate segment
    def get_segment(row):
        r, f, m = row['r_score'], row['f_score'], row['m_score']
        if r >= 4 and f >= 4 and m >= 4:
            return 'Champions'
        elif r <= 2 and (f >= 3 or m >= 3):
            return 'At Risk'
        elif r >= 4 and f <= 2:
            return 'Recent Users'
        elif r <= 2 and f <= 2:
            return 'Lost Customers'
        else:
            return 'Standard'
            
    df['rfm_segment'] = df.apply(get_segment, axis=1)
    df['rfm_concat_score'] = df['r_score'].astype(str) + df['f_score'].astype(str) + df['m_score'].astype(str)
    
    # Churn Risk
    df['is_high_churn_risk'] = df['recency_days'] > (df['avg_days_between_purchases'] + 2 * df['stddev_days_between_purchases'])
    
    return df

def get_mock_cohort_data():
    months = 12
    cohorts = []
    
    for i in range(months):
        year = 2023 + (i // 12)
        month = (i % 12) + 1
        cohort_month_str = f"{year}-{month:02d}"
        
        cohort_size = np.random.randint(500, 1500)
        
        for j in range(months - i):
            retention_rate = max(0.05, 1.0 / (j + 1) - np.random.uniform(0, 0.1))
            if j == 0:
                retention_rate = 1.0
                
            active_users = int(cohort_size * retention_rate)
            
            # Simulated progressive CLV: steep at first, then flattening out
            # Base month average spend: $30
            # Subsequent retention purchases add to cumulative CLV
            if j == 0:
                clv = 30.0
            else:
                # Add historical CLV from previous month index simulation plus new revenue
                # For mock simplicity, we construct the cumulative value deterministically based on month j
                clv = 30.0 + sum([20.0 * (1.0 / (k + 1)) for k in range(1, j+1)])
                
            cohorts.append({
                "cohort_month": cohort_month_str,
                "cohort_size": cohort_size,
                "month_number": j,
                "active_users": active_users,
                "retention_rate": retention_rate,
                "cumulative_clv": clv
            })
            
    return pd.DataFrame(cohorts)

def get_mock_market_basket_data():
    items = ['Running Shoes', 'Water Bottle', 'Gym Bag', 'Yoga Mat', 'Protein Powder', 'Resistance Bands', 'Smart Watch', 'Headphones']
    data = []
    
    np.random.seed(42)
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            item_a = items[i]
            item_b = items[j]
            pair_txn_count = np.random.randint(5, 500)
            
            support = pair_txn_count / 10000.0  # Assumes 10k total txns
            confidence_a_to_b = np.random.uniform(0.1, 0.8)
            lift = confidence_a_to_b / (np.random.randint(100, 2000) / 10000.0)
            
            data.append({
                'item_a': item_a,
                'item_b': item_b,
                'pair_txn_count': pair_txn_count,
                'support': support,
                'confidence_a_to_b': confidence_a_to_b,
                'lift': lift
            })
            
    df = pd.DataFrame(data)
    return df

def get_mock_mta_data():
    channels = ['Organic Search', 'Direct', 'Paid Search', 'Social', 'Email', 'Referral']
    
    # Establish base revenue total (e.g., 500k) divided among channels roughly
    np.random.seed(42)
    base_shares = np.random.dirichlet(np.ones(len(channels)), size=1)[0]
    total_revenue = 500000
    
    data = []
    
    for i, channel in enumerate(channels):
        base_rev = total_revenue * base_shares[i]
        
        # Variations across models based on channel type
        if channel == 'Paid Search' or channel == 'Social':
            # Paid and social often get oversized credit in first touch, suffer in last touch
            first = base_rev * 1.3
            last = base_rev * 0.7
            linear = base_rev
            u_shape = base_rev * 1.15 # Strong at both ends usually
            decay = base_rev * 0.8
        elif channel == 'Direct' or channel == 'Email':
            # Direct/Email often win in last touch, lose in first touch
            first = base_rev * 0.6
            last = base_rev * 1.4
            linear = base_rev
            u_shape = base_rev * 1.1
            decay = base_rev * 1.3
        else:
            first = base_rev
            last = base_rev
            linear = base_rev
            u_shape = base_rev
            decay = base_rev
            
        data.append({
            'channel': channel,
            'first_touch_revenue': first,
            'last_touch_revenue': last,
            'linear_revenue': linear,
            'ushaped_revenue': u_shape,
            'time_decay_revenue': decay
        })
        
    return pd.DataFrame(data).sort_values(by='linear_revenue', ascending=False)

def get_mock_funnel_data():
    return pd.DataFrame({
        'step_1_page_view': [10000],
        'step_2_view_item': [6500],
        'step_3_add_to_cart': [2200],
        'step_4_checkout': [1100],
        'step_5_purchase': [650],
        'avg_time_to_convert_minutes': [48.5]
    })

def get_mock_anomaly_data():
    np.random.seed(42)
    dates = pd.date_range(start="2023-01-01", end="2023-06-30")
    base_revenue = 5000 + np.sin(np.arange(len(dates)) / 10) * 1000
    noise = np.random.normal(0, 500, len(dates))
    
    revenue = base_revenue + noise
    
    # Inject Artificial Anomalies
    revenue[15] += 6000 # Sudden massive Spike
    revenue[40] -= 4000 # Massive drop
    revenue[90] += 5000 # Spike
    revenue[120] += 8000 # Black Friday Spike
    
    df = pd.DataFrame({
        'purchase_date': dates,
        'daily_revenue': revenue,
        'daily_orders': np.random.randint(20, 150, len(dates))
    })
    
    # Calculate rolling metrics mirroring SQL
    df['rolling_14d_avg_revenue'] = df['daily_revenue'].rolling(window=14, min_periods=1).mean()
    df['rolling_14d_stddev_revenue'] = df['daily_revenue'].rolling(window=14, min_periods=2).std().fillna(0)
    
    df['upper_band'] = df['rolling_14d_avg_revenue'] + 2 * df['rolling_14d_stddev_revenue']
    df['lower_band'] = np.maximum(0, df['rolling_14d_avg_revenue'] - 2 * df['rolling_14d_stddev_revenue'])
    
    def flag_anomaly(row):
        val = row['daily_revenue']
        if val > row['upper_band'] and row['rolling_14d_stddev_revenue'] > 0:
            return 'Spike'
        elif val < row['lower_band'] and row['rolling_14d_stddev_revenue'] > 0:
            return 'Drop'
        return 'Normal'
        
    df['anomaly_flag'] = df.apply(flag_anomaly, axis=1)
    
    return df.sort_values(by='purchase_date')
