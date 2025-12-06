#!/usr/bin/env python3
"""
Scenario Manager: Execute and manage security testing scenarios
- List available scenarios
- Run individual or batch scenarios
- Monitor execution
- Collect results
"""

import os
import sys
import json
import argparse
import logging
import subprocess
import time
from datetime import datetime
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ScenarioManager:
    def __init__(self, script_dir=None):
        self.script_dir = script_dir or Path(__file__).parent
        self.scenarios = self._discover_scenarios()
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'scenarios_executed': [],
            'total_time': 0,
            'status': 'pending'
        }

    def _discover_scenarios(self):
        """Discover available scenario scripts from all category folders"""
        scenarios = {}

        # Look in categorized folders
        category_dirs = [
            self.script_dir.parent / '1_network_attacks',
            self.script_dir.parent / '2_web_applications',
            self.script_dir.parent / '3_credential_auth',
            self.script_dir.parent / '4_malware_intrusion',
            self.script_dir.parent / '5_data_exfiltration'
        ]

        for category_dir in category_dirs:
            if not category_dir.exists():
                continue

            for file in sorted(category_dir.glob('[0-9][0-9]_*.py')):
                scenario_num = int(file.name[:2])
                scenario_name = file.name[3:-3]  # Remove XX_ and .py
                scenarios[scenario_num] = {
                    'number': scenario_num,
                    'name': scenario_name,
                    'file': file,
                    'category': category_dir.name,
                    'description': self._get_scenario_description(file)
                }

        return scenarios

    def _get_scenario_description(self, file):
        """Extract scenario description from docstring"""
        try:
            with open(file, 'r') as f:
                lines = f.readlines()
                if len(lines) > 2 and lines[1].startswith('"""'):
                    # Extract from docstring
                    for i, line in enumerate(lines[2:10]):
                        if 'Difficulty' in line or 'Description' in line:
                            return line.strip()
            return "No description available"
        except:
            return "No description available"

    def list_scenarios(self):
        """List all available scenarios by category"""
        logger.info("\n" + "="*70)
        logger.info("AVAILABLE SCENARIOS (Organized by Category)")
        logger.info("="*70)

        # Group scenarios by category
        categories = {}
        for num, scenario in sorted(self.scenarios.items()):
            cat = scenario.get('category', 'uncategorized')
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((num, scenario))

        # Display by category
        for category in sorted(categories.keys()):
            cat_name = category.replace('_', ' ').title()
            logger.info(f"\n📁 {cat_name}")
            logger.info("-" * 70)

            for num, scenario in categories[category]:
                logger.info(f"  [{num:02d}] {scenario['name'].upper()}")
                logger.info(f"      📄 {scenario['description']}")
                logger.info(f"      📍 {scenario['category']}/{scenario['file'].name}")

        logger.info("\n" + "="*70)
        logger.info(f"Total Scenarios Available: {len(self.scenarios)}")
        logger.info("="*70 + "\n")

    def run_scenario(self, scenario_num, args=None, verbose=False):
        """Run a single scenario"""
        if scenario_num not in self.scenarios:
            logger.error(f"[-] Scenario {scenario_num} not found")
            return False

        scenario = self.scenarios[scenario_num]
        logger.info(f"\n[*] Running Scenario {scenario_num}: {scenario['name'].upper()}")

        try:
            cmd = [sys.executable, str(scenario['file'])]

            if args:
                cmd.extend(args)
            if verbose:
                cmd.append('--verbose')

            start_time = time.time()
            result = subprocess.run(cmd, capture_output=False, text=True)
            elapsed = time.time() - start_time

            execution_result = {
                'scenario_number': scenario_num,
                'scenario_name': scenario['name'],
                'status': 'completed' if result.returncode == 0 else 'failed',
                'duration': elapsed,
                'return_code': result.returncode
            }

            self.results['scenarios_executed'].append(execution_result)

            if result.returncode == 0:
                logger.info(f"[+] Scenario {scenario_num} completed successfully in {elapsed:.2f}s")
                return True
            else:
                logger.error(f"[-] Scenario {scenario_num} failed with code {result.returncode}")
                return False

        except Exception as e:
            logger.error(f"[-] Failed to execute scenario {scenario_num}: {e}")
            self.results['scenarios_executed'].append({
                'scenario_number': scenario_num,
                'scenario_name': scenario['name'],
                'status': 'failed',
                'error': str(e)
            })
            return False

    def run_scenarios_batch(self, scenario_nums, delay=0, verbose=False):
        """Run multiple scenarios with optional delay"""
        logger.info(f"\n[*] Running {len(scenario_nums)} scenarios in batch")

        start_time = time.time()
        successful = 0

        for i, scenario_num in enumerate(scenario_nums):
            logger.info(f"\n[*] Running scenario {i+1}/{len(scenario_nums)}")

            if self.run_scenario(scenario_num, verbose=verbose):
                successful += 1

            if delay > 0 and i < len(scenario_nums) - 1:
                logger.info(f"[*] Waiting {delay}s before next scenario...")
                time.sleep(delay)

        elapsed = time.time() - start_time
        self.results['total_time'] = elapsed
        self.results['status'] = 'completed'

        logger.info(f"\n[+] Batch execution completed: {successful}/{len(scenario_nums)} successful in {elapsed:.2f}s")
        return successful == len(scenario_nums)

    def run_category(self, category, verbose=False):
        """Run all scenarios in a category"""
        category_scenarios = {
            'network': [1, 2, 3, 4, 5],
            'web': [6, 7, 8, 9, 10],
            'auth': [11, 12, 13, 14, 15],
            'malware': [16, 17, 18, 19, 20],
            'exfil': [21, 22, 23, 24, 25]
        }

        cat_lower = category.lower()
        if cat_lower not in category_scenarios:
            logger.error(f"[-] Unknown category: {category}")
            return False

        scenarios = category_scenarios[cat_lower]
        logger.info(f"\n[*] Running {category.upper()} scenarios: {scenarios}")

        return self.run_scenarios_batch(scenarios, verbose=verbose)

    def save_results(self, output_file='results.json'):
        """Save execution results to JSON"""
        try:
            with open(output_file, 'w') as f:
                json.dump(self.results, f, indent=2)
            logger.info(f"[+] Results saved to {output_file}")
            return True
        except Exception as e:
            logger.error(f"[-] Failed to save results: {e}")
            return False

    def print_summary(self):
        """Print execution summary"""
        logger.info("\n" + "="*70)
        logger.info("EXECUTION SUMMARY")
        logger.info("="*70)
        logger.info(f"Timestamp: {self.results['timestamp']}")
        logger.info(f"Total Scenarios Executed: {len(self.results['scenarios_executed'])}")
        logger.info(f"Total Duration: {self.results['total_time']:.2f}s")

        successful = sum(1 for r in self.results['scenarios_executed'] if r['status'] == 'completed')
        logger.info(f"Successful: {successful}/{len(self.results['scenarios_executed'])}")

        logger.info("\nDetailed Results:")
        for result in self.results['scenarios_executed']:
            status_symbol = "[+]" if result['status'] == 'completed' else "[-]"
            logger.info(f"  {status_symbol} Scenario {result['scenario_number']}: {result['scenario_name']} ({result.get('duration', 'N/A'):.2f}s)")

        logger.info("="*70 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='Security Scenario Manager',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # List all scenarios
  python scenario_manager.py --list

  # Run single scenario
  python scenario_manager.py --scenario 1 --verbose

  # Run multiple scenarios with delay
  python scenario_manager.py --scenarios 1,2,3 --delay 60

  # Run all scenarios in category
  python scenario_manager.py --category network --verbose

  # Run scenario with custom args
  python scenario_manager.py --scenario 1 --args "--target 10.10.10.10 --duration 30"

  # Run all scenarios
  python scenario_manager.py --run-all --output results.json
        '''
    )

    parser.add_argument('--list', action='store_true', help='List all available scenarios')
    parser.add_argument('--scenario', type=int, help='Run specific scenario by number')
    parser.add_argument('--scenarios', help='Run multiple scenarios (comma-separated, e.g., 1,2,3)')
    parser.add_argument('--category', help='Run all scenarios in category (network, web, auth, malware, exfil)')
    parser.add_argument('--run-all', action='store_true', help='Run all scenarios')
    parser.add_argument('--args', help='Additional arguments to pass to scenario script')
    parser.add_argument('--delay', type=int, default=0, help='Delay between scenarios (seconds)')
    parser.add_argument('--output', help='Save results to JSON file')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    manager = ScenarioManager()

    # List scenarios
    if args.list:
        manager.list_scenarios()
        return

    # Prepare scenario list
    scenarios_to_run = []

    if args.scenario:
        scenarios_to_run = [args.scenario]
    elif args.scenarios:
        try:
            scenarios_to_run = [int(s.strip()) for s in args.scenarios.split(',')]
        except ValueError:
            logger.error("[-] Invalid scenario numbers")
            sys.exit(1)
    elif args.category:
        if not manager.run_category(args.category, verbose=args.verbose):
            sys.exit(1)
        if args.output:
            manager.save_results(args.output)
        manager.print_summary()
        return
    elif args.run_all:
        scenarios_to_run = list(manager.scenarios.keys())
    else:
        parser.print_help()
        return

    # Run scenarios
    if scenarios_to_run:
        scenario_args = args.args.split() if args.args else []
        manager.run_scenarios_batch(scenarios_to_run, delay=args.delay, verbose=args.verbose)

    # Save results
    if args.output:
        manager.save_results(args.output)

    manager.print_summary()

if __name__ == '__main__':
    main()
