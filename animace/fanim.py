from manim import Square


class FiksSquare(Square):
    def __init__(self, side_length: float = 2, **kwargs) -> None:
        super().__init__(side_length, **kwargs)
        self.set_style(stroke_color="#CACACA", fill_color="#263238", fill_opacity=1)
