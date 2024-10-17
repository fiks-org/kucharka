from manim import *


class FixText(MovingCameraScene):
    def construct(self):
        npl = NumberPlane(x_range=[-20, 20, 1], x_length=40).add_coordinates()
        self.add(npl)
        circle = Circle()
        self.add(circle)

        state_label = Text("Current state: ")

        def state_label_updater(mobj):
            mobj.move_to(self.camera.frame.get_corner(UL), aligned_edge=UL)

        state_label.add_updater(state_label_updater, call_updater=True)
        self.add(state_label)
        state = always_redraw(
            lambda: Text("Alpha").next_to(state_label, RIGHT, aligned_edge=UP, buff=0.2)
        )
        self.add(state)

        for s in ["Beta", "Gamma", "Delta"]:
            self.play(self.camera.frame.animate.shift(RIGHT * 3))

            new_state = Text(s).next_to(state_label, RIGHT, aligned_edge=UP, buff=0.2)
            self.play(TransformMatchingShapes(state, new_state))
            state = always_redraw(
                lambda: new_state.next_to(state_label, RIGHT, aligned_edge=UP, buff=0.2)
            )
            # self.play(self.camera.frame.animate.shift(LEFT * 3))
