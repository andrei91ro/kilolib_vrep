Personal adaptation of the V-REP child script for the Kilobot (and controller) provided by K-TEAM in order to use the newer Kilolib C API in the V-REP simulator.

The following functions are available to the user (similar to those from kilolib, see https://www.kilobotics.com/labs for a step by step introduction):
 * message_rx()
 * message_tx()
 * message_tx_success()
 * setup()
 * loop()
 * get_ambient_light()
 * set_motion()
 * blink() - a bit faulty for the moment due to the simulation of a sleep()function using state variables (inspired from the original k-team implementation)
 * set_motor()
 * set_color()

Acknowledgments

 * The original version of the 2 child scripts was provided by K-TEAM (http://www.k-team.com) on the Kilobot Manuals/Downloads page (http://www.k-team.com/mobile-robotics-products/kilobot/manuals-downloads)
 * The Kilolib C API created by Alex Cornejo (acornejo) was the main inspiration source and is available at https://github.com/acornejo/kilolib
 * The author is affiliated with the Department of Automatic Control and Systems Engineering (http://acse.pub.ro) of the Politehnica University of Bucharest as a Ph.D. student.
