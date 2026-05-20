You are an expert software architect. We are building a "I-Ching" app from scratch. Before writing any feature code, we must establish our architecture, data schemas, and an automated verification pipeline.

This documents should be applied to all developments

### 1. Tech Stack Constraints
- Framework: Flutter
- Database: Sqlite
- LLM Integration: Gemma Local LLM
- Testing: Flutter testing library

### 2. Design approach
1. Every prompt should be limited to one function only. If you think there are more than one thing that need to be implemented, please confirmed with user to split the tasks
2. Each function should have corresponding test to verify. 
3. When each function completed, make sure all unit test are pass. If any existing test case fail, ask for confirmation if you think there is problem related to the test setup.
4. Don't assume anything. Ask user if anything unclear
5. Write down the prompt, thinking process and any file changes into logs/change_log[yyyy_mm_dd].md
