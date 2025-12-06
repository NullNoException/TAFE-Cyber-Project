# Utility Scripts & Tools

This folder contains shared utilities and tools for managing security scenarios.

## Files

### scenario_manager.py
Master scenario executor and manager.

**Features:**
- Discover and list all scenarios from categorized folders
- Run individual or multiple scenarios
- Execute scenarios by category
- Batch execution with configurable delays
- Results collection and export to JSON
- Categorized scenario display

**Usage:**

```bash
# List all scenarios (organized by category)
python scenario_manager.py --list

# Run a specific scenario
python scenario_manager.py --scenario 1 --verbose

# Run multiple scenarios with delay
python scenario_manager.py --scenarios 1,2,3 --delay 60

# Run all scenarios in a category
python scenario_manager.py --category network
python scenario_manager.py --category web
python scenario_manager.py --category auth
python scenario_manager.py --category malware
python scenario_manager.py --category exfil

# Run all scenarios
python scenario_manager.py --run-all

# Export results
python scenario_manager.py --scenario 1 --output results.json

# Get detailed help
python scenario_manager.py --help
```

**Examples:**

```bash
# Test network detection
python scenario_manager.py --category network --verbose

# Run scenarios 1, 5, 10 with 120 second delays
python scenario_manager.py --scenarios 1,5,10 --delay 120

# Run everything and save results
python scenario_manager.py --run-all --output test_results_$(date +%s).json
```

### scenario_template.py
Template for creating custom scenarios.

**Usage:**
1. Copy this file: `cp scenario_template.py ../X_category/XX_my_scenario.py`
2. Edit the ScenarioTemplate class with your attack logic
3. Test it: `python XX_my_scenario.py --target [target] --verbose`

**Template Structure:**
- `__init__()` - Initialize scenario parameters
- `execute_attack()` - Main attack execution logic
- `log_results()` - Log scenario results
- `main()` - Command-line interface

### requirements.txt
Python package dependencies.

**Current packages:**
```
requests==2.31.0        # HTTP library for web scenarios
scapy==2.5.0           # Network packet crafting
paramiko==3.3.1        # SSH library for tunneling
pexpect==4.9.0         # Expect-like functionality
dnspython==2.4.2       # DNS library for DNS scenarios
httpx==0.25.1          # Modern HTTP client
pytest==7.4.3          # Testing framework (optional)
```

**Installation:**
```bash
pip install -r requirements.txt
```

## Directory Structure

```
utils/
├── scenario_manager.py      # Master scenario controller
├── scenario_template.py     # Template for new scenarios
├── requirements.txt         # Python dependencies
└── README.md               # This file
```

## Key Features

### 1. Scenario Discovery
Automatically discovers scenarios from category folders:
- `../1_network_attacks/`
- `../2_web_applications/`
- `../3_credential_auth/`
- `../4_malware_intrusion/`
- `../5_data_exfiltration/`

### 2. Category-Based Execution
```bash
# Network attacks
python scenario_manager.py --category "1_network_attacks"

# Web applications
python scenario_manager.py --category "2_web_applications"

# Authentication/Credentials
python scenario_manager.py --category "3_credential_auth"

# Malware/Intrusion
python scenario_manager.py --category "4_malware_intrusion"

# Data Exfiltration
python scenario_manager.py --category "5_data_exfiltration"
```

### 3. Batch Execution
```bash
# Run with delays between scenarios
python scenario_manager.py --scenarios 1,2,3,4,5 --delay 120

# Run all and collect results
python scenario_manager.py --run-all --output batch_results.json
```

### 4. Results Export
```bash
# JSON format (recommended)
python scenario_manager.py --scenario 1 --output results.json

# View results
cat results.json | python -m json.tool

# Parse results programmatically
python -c "import json; data=json.load(open('results.json')); print(data['scenarios_executed'])"
```

## Creating Custom Scenarios

### Step 1: Copy Template
```bash
cp scenario_template.py ../4_malware_intrusion/16_reverse_shell.py
```

### Step 2: Edit Class
```python
class ReverseShellScenario:
    def __init__(self, target, port=4444, ...):
        self.target = target
        # Your initialization

    def execute_attack(self):
        """Main attack logic"""
        # Your code here
        pass

    def log_results(self):
        """Log results"""
        # Your logging
        pass
```

### Step 3: Test
```bash
python ../4_malware_intrusion/16_reverse_shell.py --target web.cyberlab.local --verbose
```

### Step 4: Integrate
Once tested, the scenario_manager will auto-discover it:
```bash
python scenario_manager.py --list
# Will show your new scenario
```

## Common Parameters

All scenario scripts support these parameters:

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `--target` | string | Target hostname/IP | web.cyberlab.local |
| `--port` | int | Target port | Scenario-specific |
| `--duration` | int | Attack duration (seconds) | Scenario-specific |
| `--intensity` | int | Attack intensity (1-10) | 5 |
| `--verbose` | flag | Enable debug logging | False |

## Troubleshooting

### "Module not found" Error
```bash
pip install -r requirements.txt
```

### "Scenario not found" Error
```bash
# Verify scenario file exists
ls -la ../1_network_attacks/01_syn_flood.py

# Check it's executable
chmod +x ../1_network_attacks/01_syn_flood.py
```

### Import Errors
```bash
# Upgrade pip
pip install --upgrade pip

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Permission Denied (Network Scenarios)
Some scenarios (especially network) may need elevated privileges:
```bash
# Run with sudo
sudo python scenario_manager.py --category network

# Or use Docker
docker run --privileged -it -v $(pwd):/app python:3.9 python /app/utils/scenario_manager.py --list
```

## Performance Tuning

### Parallel Execution
For faster testing, run scenarios in parallel:
```bash
# Terminal 1
python scenario_manager.py --scenario 1 &

# Terminal 2
python scenario_manager.py --scenario 6 &

# Terminal 3
python scenario_manager.py --scenario 11 &

# Wait for all
wait
```

### Resource Optimization
```bash
# Lower intensity for reduced resource usage
python scenario_manager.py --scenario 1 --args "--intensity 2"

# Shorter duration
python scenario_manager.py --scenario 3 --args "--duration 15"
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Security Scenarios
on: [schedule]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run scenarios
        run: |
          pip install -r infra/scripts/pro-scenarios/utils/requirements.txt
          python infra/scripts/pro-scenarios/utils/scenario_manager.py --run-all --output results.json
      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: scenario-results
          path: results.json
```

## Advanced Usage

### Programmatic Execution
```python
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent))
from scenario_manager import ScenarioManager

manager = ScenarioManager()
manager.list_scenarios()
manager.run_scenario(1, verbose=True)
manager.save_results('output.json')
```

### Custom Results Processing
```python
import json

with open('results.json') as f:
    results = json.load(f)

for execution in results['scenarios_executed']:
    if execution['status'] == 'failed':
        print(f"Scenario {execution['scenario_number']} failed!")
```

## Monitoring Integration

The scenario manager works best with:
- **Wazuh:** https://wazuh.cyberlab.local
- **Prometheus:** http://prometheus.cyberlab.local
- **Grafana:** http://grafana.cyberlab.local
- **Netdata:** http://netdata.cyberlab.local

Open these in separate browser tabs while running scenarios to monitor real-time results.

## Documentation

- Scenario details: See [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md)
- Monitoring guide: See [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md)
- Implementation guide: See [REMAINING_SCENARIOS.md](../REMAINING_SCENARIOS.md)
- Category guides: See README.md in each category folder

## Support

For issues or feature requests:
1. Check the README in the specific category folder
2. Review [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md) for scenario details
3. Check [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md) for monitoring help
4. Review Docker logs: `docker logs [service-name]`
