from manim import (
    DOWN,
    PI,
    UL,
    Animation,
    FadeOut,
    Indicate,
    MovingCameraScene,
    Scene,
    TransformMatchingShapes,
    TransformMatchingTex,
    VGroup,
    Text,
    Square,
    WHITE,
    BLUE,
    RIGHT,
    UP,
    LEFT,
    FadeIn,
    always_redraw,
    config,
)


config.background_color = "#1c282e"


class FiksSquare(Square):
    def __init__(self, side_length: float = 2, **kwargs) -> None:
        super().__init__(side_length, **kwargs)
        self.set_style(stroke_color="#CACACA", fill_color="#263238", fill_opacity=1)


class MergeSort(MovingCameraScene):
    def change_state(self, state: str):
        new_state = Text(state).next_to(
            self.fiks_state_label, RIGHT, aligned_edge=UP, buff=0.2
        )
        self.play(TransformMatchingShapes(self.fiks_state, new_state), run_time=0.3)
        self.fiks_state = always_redraw(
            lambda: new_state.next_to(
                self.fiks_state_label, RIGHT, aligned_edge=UP, buff=0.2
            )
        )

    def create_array_group(self, arr):
        array_mobs = [
            FiksSquare().scale(0.5)  # .set_color(WHITE).set_fill(BLUE, opacity=0.8)
            for _ in arr
        ]
        labels = [Text(str(num)).scale(0.6) for num in arr]

        boxes = [
            VGroup(square.move_to(square.get_center()), label)
            for square, label in zip(array_mobs, labels)
        ]
        for box, n in zip(boxes, arr):
            box.__setattr__("fiks_value", n)

        arr_group = VGroup(*boxes).arrange(RIGHT, buff=0.1)

        return arr_group

    def merge(self, a1, a2):
        self.change_state("Merge")
        if not len(a2):
            return a1
        na = VGroup()

        def move_smallest(sm, bg, updown, na):
            lg = Text("<")
            lg.move_to(sm[0].get_center() + updown * UP)
            self.play(FadeIn(lg))
            self.play(lg.animate.rotate(updown * PI / 2))
            self.play(Indicate(sm[0]), run_time=0.5)
            b = sm[0]
            sm.remove(b)
            self.play(
                b.animate.next_to(na, RIGHT, aligned_edge=UP, buff=0.2)
                if len(na)
                else b.animate.move_to(pos_to_move),
                FadeOut(lg),
                sm.animate.align_to(bg, LEFT) if len(sm) else Animation(None),
                # run_time=0.5,
            )
            na += b

        if len(a2):
            self.play(
                a2.animate.move_to(a1.get_center() + DOWN * 2).align_to(a1, LEFT),
                self.camera.frame.animate.move_to(
                    a1[0].get_center() + DOWN * 2 * a1.height
                ),
            )
        else:
            self.play(
                self.camera.frame.animate.move_to(a1[0].get_center()),
            )
        while len(a1) and len(a2):
            pos_to_move = a2[0].get_center() + DOWN * 2 * a1.height
            if a1[0].fiks_value < a2[0].fiks_value:
                move_smallest(a1, a2, -1, na)
            else:
                move_smallest(a2, a1, 1, na)
        if len(a1):
            a = a1
        elif len(a2):
            a = a2
        else:
            return na
        if len(na):
            pos_to_move = na.get_right() + RIGHT * a.width
        else:
            pos_to_move = a.get_center() + DOWN * 2 * a[0].height
        self.play(a.animate.next_to(na, RIGHT, aligned_edge=UP, buff=0.2))
        for b in a:
            # self.play(Indicate(b))
            na += b
        return na

    def merge_sort(self, arr):
        self.change_state("Split")
        move_r = arr[0 : len(arr) // 2].width / 2
        if len(arr) > 1:
            self.play(
                # arr[: len(arr) // 2].animate.shift(LEFT * 2),
                self.camera.frame.animate.move_to(arr.get_center())
            )
            self.play(
                arr[len(arr) // 2 :].animate.shift(RIGHT * move_r),
                arr[: len(arr) // 2].animate.shift(LEFT * move_r),
            )
            a = self.merge_sort(arr[0 : len(arr) // 2])
            b = self.merge_sort(arr[len(arr) // 2 :])
            r = self.merge(a, b)
        else:
            # r = self.merge(arr, VGroup())
            return arr
        self.play(
            # b.animate.shift(LEFT * move_r),
            self.camera.frame.animate.move_to(r.get_center()),
        )
        # self.wait(0.5)
        return r

    def construct(self):
        arr = [38, 27, 43, 3, 9, 82, 10]
        # arr = [38, 27, 43, 3]
        # arr = [
        #     37,
        #     68,
        #     61,
        #     77,
        #     98,
        #     31,
        #     2,
        #     85,
        #     64,
        #     92,
        #     89,
        #     68,
        #     73,
        #     14,
        #     80,
        #     56,
        #     32,
        #     37,
        #     6,
        #     46,
        # ]
        arr_group = self.create_array_group(arr)

        self.fiks_state_label = (
            Text("Current operation: ")
            .align_to(self.camera.frame, UP)
            .align_to(self.camera.frame, LEFT)
            .shift(RIGHT * 0.5)
            .shift(DOWN * 0.5)
        )
        self.fiks_state = always_redraw(
            lambda: Text("Start").next_to(
                self.fiks_state_label, RIGHT, aligned_edge=UP, buff=0.2
            )
        )
        # self.fiks_state_group = (
        #     VGroup(self.fiks_state_label, self.fiks_state).arrange(RIGHT).to_corner(UL)
        # )
        self.fiks_state.align_to(self.fiks_state_label, UP)

        self.add(self.fiks_state_label)
        self.fiks_state_label.add_updater(
            lambda m: m.align_to(self.camera.frame, UP)
            .align_to(self.camera.frame, LEFT)
            .shift(RIGHT * 0.5)
            .shift(DOWN * 0.5)
        )
        self.play(
            FadeIn(arr_group), FadeIn(self.fiks_state_label), FadeIn(self.fiks_state)
        )
        self.wait(1)

        self.merge_sort(arr_group)

        # self.merge_sort(arr, 0, len(arr) - 1, arr_group)

        self.wait(2)
