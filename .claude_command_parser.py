#!/usr/bin/env python3
"""
Claude Command Monitor - Real-time monitoring of Claude bash commands
Watches JSONL files for new bash commands and logs them to ~/.claude_command_log.txt
"""

import json
import os
import time
import glob
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import argparse


class ClaudeCommandHandler(FileSystemEventHandler):
    def __init__(self, log_file):
        self.log_file = log_file
        self.processed_lines = {}  # Track processed lines per file
        
    def on_modified(self, event):
        if event.is_directory or not event.src_path.endswith('.jsonl'):
            return
            
        self.process_file(event.src_path)
    
    def on_created(self, event):
        if event.is_directory or not event.src_path.endswith('.jsonl'):
            return
            
        self.process_file(event.src_path)
    
    def process_file(self, filepath):
        """Process new lines in a JSONL file"""
        try:
            # Get the last processed line for this file
            last_line = self.processed_lines.get(filepath, 0)
            
            with open(filepath, 'r') as f:
                # Skip to the last processed line
                for _ in range(last_line):
                    f.readline()
                
                # Process new lines
                line_num = last_line
                for line in f:
                    line_num += 1
                    try:
                        entry = json.loads(line.strip())
                        
                        # Look for assistant entries with Bash tool usage
                        if entry.get('type') == 'assistant':
                            message = entry.get('message', {})
                            
                            if isinstance(message, dict) and 'content' in message:
                                content = message['content']
                                if isinstance(content, list):
                                    for item in content:
                                        if (isinstance(item, dict) and 
                                            item.get('type') == 'tool_use' and 
                                            item.get('name') == 'Bash'):
                                            
                                            self.log_command(entry, item)
                    
                    except json.JSONDecodeError:
                        continue
                
                # Update the last processed line
                self.processed_lines[filepath] = line_num
                
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
    
    def log_command(self, entry, tool_item):
        """Log a bash command to the log file"""
        input_data = tool_item.get('input', {})
        command = input_data.get('command', '')
        description = input_data.get('description', '')
        
        timestamp = entry.get('timestamp', '')
        cwd = entry.get('cwd', '')
        session_id = entry.get('sessionId', '')
        
        # Format timestamp
        if timestamp:
            try:
                dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                formatted_time = dt.strftime("%Y%m%d %H:%M")
            except:
                formatted_time = timestamp
        else:
            formatted_time = datetime.now().strftime("%Y%m%d %H:%M")
        
        # Build log entry
        log_entry = f"{command} ### [CLAUDE]"
        
        if description:
            log_entry += f" {description}"
        
        log_entry += f" {formatted_time}"
        
        if cwd:
            log_entry += f" {cwd}"
        
        if session_id:
            log_entry += f" session:{session_id[:8]}"
        
        # Append to log file
        with open(self.log_file, 'a') as f:
            f.write(log_entry + '\n')
        
        print(f"Logged: {command[:50]}...")


def monitor_claude_commands(project_filter=None, log_file="~/.claude_command_log.txt"):
    """Monitor Claude projects for new bash commands"""
    log_file = os.path.expanduser(log_file)
    claude_projects_dir = os.path.expanduser("~/.claude/projects")
    
    # Set up observer
    observer = Observer()
    handler = ClaudeCommandHandler(log_file)
    
    # Find directories to watch
    if project_filter:
        pattern = f"*{project_filter}*"
        watch_dirs = glob.glob(os.path.join(claude_projects_dir, pattern))
    else:
        watch_dirs = [claude_projects_dir]
    
    # Add watches
    for watch_dir in watch_dirs:
        observer.schedule(handler, watch_dir, recursive=True)
        print(f"Watching: {watch_dir}")
    
    # Process existing files first
    print("Processing existing files...")
    for watch_dir in watch_dirs:
        for jsonl_file in glob.glob(os.path.join(watch_dir, "**/*.jsonl"), recursive=True):
            handler.process_file(jsonl_file)
    
    # Start monitoring
    observer.start()
    print(f"Monitoring started. Logging to {log_file}")
    print("Press Ctrl+C to stop...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nMonitoring stopped.")
    
    observer.join()


def main():
    parser = argparse.ArgumentParser(
        description='Monitor Claude sessions for bash commands in real-time'
    )
    parser.add_argument(
        '-p', '--project-filter',
        help='Filter projects by name (e.g., "georgia")',
        default=None
    )
    parser.add_argument(
        '-l', '--log-file',
        help='Log file path (default: ~/.claude_command_log.txt)',
        default='~/.claude_command_log.txt'
    )
    
    args = parser.parse_args()
    
    # Check if watchdog is installed
    try:
        import watchdog
    except ImportError:
        print("Error: watchdog package is required.")
        print("Install with: pip install watchdog")
        return 1
    
    monitor_claude_commands(
        project_filter=args.project_filter,
        log_file=args.log_file
    )


if __name__ == '__main__':
    main()