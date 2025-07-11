namespace VoiceCommandProcessor
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this._statusLabel = new System.Windows.Forms.Label();
            this._startButton = new System.Windows.Forms.Button();
            this._stopButton = new System.Windows.Forms.Button();
            this._logTextBox = new System.Windows.Forms.TextBox();
            this.SuspendLayout();
            // 
            // _statusLabel
            // 
            this._statusLabel.Font = new System.Drawing.Font("Arial", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this._statusLabel.ForeColor = System.Drawing.Color.Gray;
            this._statusLabel.Location = new System.Drawing.Point(20, 20);
            this._statusLabel.Name = "_statusLabel";
            this._statusLabel.Size = new System.Drawing.Size(300, 30);
            this._statusLabel.TabIndex = 0;
            this._statusLabel.Text = "Server Bağlantısı :";
            this._statusLabel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // _startButton
            // 
            this._startButton.BackColor = System.Drawing.Color.LightGreen;
            this._startButton.Font = new System.Drawing.Font("Arial", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this._startButton.Location = new System.Drawing.Point(20, 60);
            this._startButton.Name = "_startButton";
            this._startButton.Size = new System.Drawing.Size(100, 30);
            this._startButton.TabIndex = 1;
            this._startButton.Text = "Başlat";
            this._startButton.UseVisualStyleBackColor = false;
            this._startButton.Click += new System.EventHandler(this.StartButton_Click);
            // 
            // _stopButton
            // 
            this._stopButton.BackColor = System.Drawing.Color.LightCoral;
            this._stopButton.Enabled = false;
            this._stopButton.Font = new System.Drawing.Font("Arial", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this._stopButton.Location = new System.Drawing.Point(130, 60);
            this._stopButton.Name = "_stopButton";
            this._stopButton.Size = new System.Drawing.Size(100, 30);
            this._stopButton.TabIndex = 2;
            this._stopButton.Text = "Durdur";
            this._stopButton.UseVisualStyleBackColor = false;
            this._stopButton.Click += new System.EventHandler(this.StopButton_Click);
            // 
            // _logTextBox
            // 
            this._logTextBox.BackColor = System.Drawing.Color.Black;
            this._logTextBox.Font = new System.Drawing.Font("Consolas", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this._logTextBox.ForeColor = System.Drawing.Color.LightGreen;
            this._logTextBox.Location = new System.Drawing.Point(20, 100);
            this._logTextBox.Multiline = true;
            this._logTextBox.Name = "_logTextBox";
            this._logTextBox.ReadOnly = true;
            this._logTextBox.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this._logTextBox.Size = new System.Drawing.Size(544, 350);
            this._logTextBox.TabIndex = 3;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(584, 461);
            this.Controls.Add(this._statusLabel);
            this.Controls.Add(this._startButton);
            this.Controls.Add(this._stopButton);
            this.Controls.Add(this._logTextBox);
            this.Name = "Form1";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Nexon";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label _statusLabel;
        private System.Windows.Forms.Button _startButton;
        private System.Windows.Forms.Button _stopButton;
        private System.Windows.Forms.TextBox _logTextBox;
    }
}