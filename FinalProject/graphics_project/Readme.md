#  Collaborative Painting - 404 Team Not Found
Collaborative Paint is a desktop application that allows multiple users to paint collaboratively in real-time.  It is developed by Agastya Das, Heekyung Kim, Roydon Pereira, Jake Stringfellow, and Jiayue Zhao. The Paint Factory requested this application to facilitate remote collaboration between teams. As users draw on one application, it updates in real-time on all others who have joined the session.

# Demo video
// TODO: add demo video link

# Technologies Used
The Collaborative Paint application was developed using DLang programming language and the SDL library for graphic user interface (GUI) development. The application's build system uses Dub.

# Functionality
The Collaborative Paint application allows users to connect to a server and collaborate on a single drawing. Users can choose between drawing offline or connecting to a server for collaborative drawing. The application provides the following features:
* Drawing with different brush types, colors, and sizes.
* Undo and redo functionalities.
* Erasing pixels.
* Connecting to a server and collaborating in real-time.
* Saving and opening drawings.


# Prerequisites
* DUB package manager
* D language compiler
* SDL Library: bindbc-sdl

# How to Run
Clone or download the project repository to your local machine.
Open a terminal and navigate to the project root directory.

## Starting a server
* Run ‘dub run -c=Server’ in the terminal to build and run the server application.
```bash
dub run -c=Server
```
* After seeing prompt for server getting started, share the IP address for clients to join collaborative painting.
* The application would render message for new clients joining on the server side.
* Once the server is closed, clients are still able to paint offline.

## Collaborative drawing Online
* Run dub run to start the application.
```bash
dub run
```
* The app will ask if you want to start/join a collaboration session with your friends.
```bash
Do you want to start/join a collaboration session with your friends? (y/n):
> 
```
* Type y to connect to a server, or n to start drawing offline.
* If you chose to connect to a server, enter the IP address and port number of the server when prompted.
* Once connected, start drawing on the canvas!
* To exit the app, close the window or press Ctrl+C in the terminal
* Your drawings will be sent to the server and shared with other users who are also connected.
* If the server is closed or the port number is incorrect, you will be prompted to start the app offline or try again to connect.

## Drawing Offline
If you choose not to connect to a server, you can still draw on the canvas offline. 
* Simply choose "n" when prompted to start or join a collaboration session, and you will be taken to the canvas where you can draw.

## Run the tests
```bash
dub test
```
All our unittest cases pass. However, `Invalid memory operation Exception` is raised **after** the unittests are completed just for testNework.d as garbage collector cannot clear some variables from the client class as they are not allocated to the memory.

We commented out the unittest on testNework.d for CI/CD purposes. Please uncomment when running the test.  


## Future Implementation
- Wider range of brush colors and types
- Include additional undo/redo functionality such as undoing eraser marks, etc. 

