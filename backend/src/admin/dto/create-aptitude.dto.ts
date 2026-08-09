import { IsArray, IsInt, IsString } from 'class-validator';

export class CreateAptitudeDto {
  @IsString() category: string;
  @IsString() question: string;
  @IsArray() options: string[];
  @IsInt() correctOption: number;
}
